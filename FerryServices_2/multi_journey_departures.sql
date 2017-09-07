WITH MultiLinkSections AS 
(
    SELECT RouteSectionId
    FROM RouteLink RL 
	WHERE RL.FromStopPointRef = ?
    AND RL.ToStopPointRef = ?
    AND RL.RouteSectionId IN
    (
        SELECT RL.RouteSectionId 
        FROM RouteLink RL 
        GROUP BY RL.RouteSectionId HAVING COUNT(*) > 1
    )
),

VehicleJourneysOperatingToday AS 
(
    SELECT VehicleJourneyRef
    FROM DayOfOperation DOO
    WHERE ? >= DOO.StartDate
    AND ? <= DOO.EndDate
),

VehicleJourneysNotOperatingToday AS 
(
    SELECT VehicleJourneyRef
    FROM DayOfNonOperation DONO
    WHERE ? >= DONO.StartDate
    AND ? <= DONO.EndDate
),

FromStopPointRef AS 
(
    SELECT *
    FROM AnnotatedStopPointRef ASPR
),

ToStopPointRef AS 
(
    SELECT *
    FROM AnnotatedStopPointRef ASPR
)

SELECT RL.RouteSectionId as RouteSectionId, FSPR.StopPointRef as FromCode, FSPR.CommonName AS `From`, TSPR.StopPointRef AS ToCode, TSPR.CommonName AS `To`, VJ.DepatureHour AS Hour, VJ.DepatureMinute AS Minute, JPTL.RunTime AS RunTime, JPTL.WaitTime AS WaitTime, RL.`Order` as `Order`, VJ.Note AS Note
FROM RouteLink RL 
INNER JOIN MultiLinkSections MLS ON RL.RouteSectionId = MLS.RouteSectionId
INNER JOIN JourneyPatternTimingLink JPTL ON JPTL.RouteLinkRef = RL.RouteLinkId
INNER JOIN JourneyPattern JP ON JPTL.JourneyPatternSectionid = JP.JourneyPatternId
INNER JOIN VehicleJourney VJ ON VJ.JourneyPatternRef = JP.JourneyPatternId
INNER JOIN Service S ON S.ServiceCode = JP.ServiceRef
INNER JOIN FromStopPointRef FSPR ON FSPR.StopPointRef = JPTL.JourneyPatternFromStopPointRef
INNER JOIN ToStopPointRef TSPR ON TSPR.StopPointRef = JPTL.JourneyPatternToStopPointsRef
WHERE VJ.{{dayOfWeek}} = 1
AND 
(
    (? >= S.StartDate AND ? <= S.EndDate)
    OR
    (VJ.VehicleJourneyCode IN VehicleJourneysOperatingToday)
)
AND VJ.VehicleJourneyCode NOT IN VehicleJourneysNotOperatingToday
