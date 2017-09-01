SELECT JPTL.JourneyPatternFromStopPointRef AS `From`, JPTL.JourneyPatternToStopPointsRef AS `To`
FROM Service S
INNER JOIN JourneyPattern JP ON JP.ServiceRef = S.ServiceCode
INNER JOIN JourneyPatternTimingLink JPTL ON JPTL.JourneyPatternSectionId = JP.JourneyPatternSectionRef
WHERE S.CalMacServiceId = ?
