SELECT sp.StopPointId, sp.Name, sp.Latitude, sp.Longitude FROM
(
    SELECT toStopPoint.StopPointId
    FROM Journey j
    INNER JOIN Service s on s.ServiceId == j.ServiceId
    INNER JOIN JourneyPattern jp on jp.JourneyPatternId == j.JourneyPatternId
    INNER JOIN StopPoint toStopPoint on toStopPoint.StopPointId == jp.FromStopPoint
    WHERE s.CalMacServiceId = (?)

    UNION

    SELECT fromStopPoint.StopPointId
    FROM Journey j
    INNER JOIN Service s on s.ServiceId == j.ServiceId
    INNER JOIN JourneyPattern jp on jp.JourneyPatternId == j.JourneyPatternId
    INNER JOIN StopPoint fromStopPoint on fromStopPoint.StopPointId == jp.FromStopPoint
    WHERE s.CalMacServiceId = (?)
) filteredStopPoints
INNER JOIN StopPoint sp ON sp.StopPointId == filteredStopPoints.StopPointId