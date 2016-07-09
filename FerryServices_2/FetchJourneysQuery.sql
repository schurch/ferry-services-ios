SELECT fromStopPoint.Name as FromTerminal,
    toStopPoint.Name as ToTerminal,
    j.DepartureHour,
    j.DepartureMinute,
    jp.RunTime

FROM Journey j
INNER JOIN Service s on s.ServiceId == j.ServiceId
INNER JOIN JourneyPattern jp on jp.JourneyPatternId == j.JourneyPatternId
INNER JOIN StopPoint fromStopPoint on fromStopPoint.StopPointId == jp.FromStopPoint
INNER JOIN StopPoint toStopPoint on toStopPoint.StopPointId == jp.ToStopPoint

WHERE (?) >= s.StartDate AND (?) <= s.EndDate
    AND JourneyId NOT IN (SELECT JourneyId FROM NonOperationDate WHERE (?) >= StartDate AND (?) <= EndDate)
    AND 1 << strftime('%w', datetime((?), 'unixepoch')) & j.DaysOfWeekMask == 1 << strftime('%w', datetime((?), 'unixepoch'))
    AND s.CalMacServiceId = (?)

ORDER BY FromTerminal, j.DepartureHour, j.DepartureMinute;