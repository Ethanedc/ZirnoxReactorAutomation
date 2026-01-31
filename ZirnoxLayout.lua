local ZirnoxLayout = {}

-- =========================================================
-- CO2 heuristics
-- =========================================================

function ZirnoxLayout.getBestCO2(reactor)
    if reactor.heat == 0 then
        return 0
    end

    return math.floor(
        0.7 * reactor.heat / reactor.maxHeat * 14000
    )
end

function ZirnoxLayout.getBestCO2_opt(reactor)
    if reactor.heat <= 10256 then
        return 0
    end

    local ret =
        math.min(
            14000,
            14000 * math.sqrt((reactor.heat - 10256) / reactor.heat)
        )

    return math.floor(ret)
end

function ZirnoxLayout.getBestCO2_aggresive(reactor)
    local co2

    if reactor.heat > 10256 then
        co2 = 14000
    else
        co2 = 14000 * reactor.heat / 10256
    end

    return math.min(math.floor(co2), reactor.maxCarbonDioxide)
end

function ZirnoxLayout.getBestCO2_aggresive2(reactor)
    local x = (reactor.heat - 60000) / 40000
    local ret = math.min(
        16000,
        14000 + 2000 * (x * x * x)
    )

    return math.floor(ret)
end

-- =========================================================
-- Layout solver (prioritize heat efficiency)
-- =========================================================

function ZirnoxLayout.solveEfficient(reactor)
    local bestRodIdx = reactor:getMostPowerfullRodFromBridge()
    if not bestRodIdx then return end

    local bRod = reactor:getRodFromBridge(bestRodIdx)

    -- CO2 policy (aggressive overclock)
    reactor.carbonDioxide = ZirnoxLayout.getBestCO2_aggresive2(reactor)

    -- =====================================================
    -- Main chamber pass
    -- =====================================================
    for y = 1, #reactor.reactorChamber do
        for x = 1, #reactor.reactorChamber[y] do
            local rod = reactor:getRodAt(x, y)

            -- Fully surrounded (no blocks)
            if not reactor:getRodUp(x, y):isBlock()
            and not reactor:getRodDown(x, y):isBlock()
            and not reactor:getRodLeft(x, y):isBlock()
            and not reactor:getRodRight(x, y):isBlock()
            then
                if rod:isEmpty() then
                    reactor:pullRodFromBridge(bestRodIdx, x, y)
                else
                    if bRod.strength > rod.strength then
                        reactor:replaceRodWithBridgeRod(bestRodIdx, x, y)
                    end
                end
            end

            -- Strong neighbour cluster
            if reactor:getRodNeightbourCountT(x, y, rod.strength) > 1 then
                if rod:isEmpty() then
                    reactor:pullRodFromBridge(bestRodIdx, x, y)
                else
                    if bRod.strength > rod.strength then
                        reactor:replaceRodWithBridgeRod(bestRodIdx, x, y)
                    end
                end
            end

            -- Weak / sparse area
            if reactor:getRodNeightbourCount(x, y) == 1
            or reactor:getEmptyNeightbourCount(x, y) <= 2
            then
                if rod:isEmpty() then
                    reactor:pullRodFromBridge(bestRodIdx, x, y)
                else
                    if bRod.strength < rod.strength then
                        reactor:replaceRodWithBridgeRod(bestRodIdx, x, y)
                    end
                end
            end
        end
    end

    -- =====================================================
    -- Move isolated rods
    -- =====================================================
    local aloneRods = reactor:getAloneRods(3)

    for i = 1, #aloneRods do
        local aRod = aloneRods[i]

        for y = 1, #reactor.reactorChamber do
            for x = 1, #reactor.reactorChamber[y] do
                if x == aRod.x and y == aRod.y then
                    goto continue
                end

                local rod = reactor:getRodAt(x, y)

                if not reactor:getRodUp(x, y):isBlock()
                and not reactor:getRodDown(x, y):isBlock()
                and not reactor:getRodLeft(x, y):isBlock()
                and not reactor:getRodRight(x, y):isBlock()
                then
                    if rod:isEmpty() then
                        reactor:moveRod(aRod.x, aRod.y, x, y)
                    end
                end

                ::continue::
            end
        end
    end
end

return ZirnoxLayout
