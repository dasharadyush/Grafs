/*МДЗ6*/
/*1)Вывести названия городов, расстояния между которыми минимально среди предложенных маршрутов  */
SELECT Top 1 with ties (SELECT Название FROM Города WHERE Город_ID = Город_ID_1) as Город_1, (SELECT Название FROM Города WHERE Город_ID = Город_ID_2) as Город_2
FROM Маршруты
ORDER BY Расстояние
/*2)Вывести названия городов, находящихся в одной области, расстояния между которыми минимально среди предложенных маршрутов между городами в одной области*/
SELECT TOP 1 with ties Города1.Название as Город_1, Города.Название as Город_2
FROM (Маршруты LEFT JOIN Города as Города1 ON Город_ID = Город_ID_1) LEFT JOIN Города ON Города.Город_ID = Город_ID_2
WHERE Города1.Область_ID = Города.Область_ID
ORDER BY Расстояние
/*3)Вывести города, для которых нет информации в таблице Маршруты (сортировку сделала для красоты)*/ 
SELECT T2.Город_ID as Город_ID_1, T1.Город_ID as Город_ID_2
FROM Города T1 CROSS JOIN Города T2
WHERE T1.Город_ID != T2.Город_ID AND T2.Город_ID < T1.Город_ID
EXCEPT 
SELECT Город_ID_1, Город_ID_2
FROM Маршруты
ORDER BY Город_ID_1
/*4)Если предположить, что двигаться можно только из Город_ID_1 в Город_ID_2, выведите города, в которые нельзя попасть, если Вы не в них в начальный момент времени.*/
SELECT distinct Город_ID_1
FROM Маршруты
WHERE Город_ID_1 not in (SELECT Город_ID_2 FROM Маршруты)
/*5)Если предположить, что двигаться можно только из Город_ID_1 в Город_ID_2, выведите города, из которых нельзя выехать, если Вы в них в начальный момент времени.*/
SELECT М1.Город_ID_2
FROM Маршруты М1 LEFT JOIN Маршруты М2 ON М1.Город_ID_2 = М2.Город_ID_1
WHERE М2.Город_ID_1 is NULL
/*6)В начальный момент времени Вы находитесь в городе с идентификатором, заданным параметром. 
Выведите список всех городов, в которые Вы можете попасть не более чем за 3 шага.*/

--- Содала временную таблицу, куда добавила и обратные пути:
/*CREATE TABLE #Маршруты_3 (Город_ID_1 int NOT NULL, Город_ID_2 int NOT NULL, Расстояние float NOT NULL)
INSERT #Маршруты_3
SELECT Город_ID_1, Город_ID_2, Расстояние FROM Маршруты 
GO
INSERT #Маршруты_3
SELECT Город_ID_2, Город_ID_1, Расстояние FROM Маршруты 
GO*/

DECLARE @p int
SET @p = 4

SELECT Город_ID_2 as Город_ID
FROM #Маршруты_3 М1 
WHERE Город_ID_1 = @p
UNION
SELECT М2.Город_ID_2 as Город_ID
FROM #Маршруты_3 М1 LEFT JOIN #Маршруты_3 М2 ON М1.Город_ID_2 = М2.Город_ID_1 
WHERE М1.Город_ID_1 != М2.Город_ID_2 AND М1.Город_ID_1 = @p
UNION
SELECT М3.Город_ID_2 as Город_ID
FROM #Маршруты_3 М1 LEFT JOIN #Маршруты_3 М2 ON М1.Город_ID_2 = М2.Город_ID_1 LEFT JOIN #Маршруты_3 М3 ON М2.Город_ID_2 = М3.Город_ID_1
WHERE М1.Город_ID_1 != М2.Город_ID_2 AND М1.Город_ID_1 != М3.Город_ID_2 AND М2.Город_ID_1 != М3.Город_ID_2 AND М1.Город_ID_1 = @p

/*7)Вывести идентификаторы Город_ID_1 и Город_ID_2 такие, что сумма расстояний между каким-то Город_ID и Город_ID_1 и Город_ID и Город_ID_2 меньше, 
чем расстояние между Город_ID_1 и Город_ID_2. */
SELECT DISTINCT М3.Город_ID_1, М3.Город_ID_2
FROM 
(SELECT М1.Город_ID_1 as Город_ID_1, М2.Город_ID_2 as Город_ID_2, (М1.Расстояние + М2.Расстояние) as Расстояние
FROM (#Маршруты_3 М1 LEFT JOIN #Маршруты_3 М2 ON М1.Город_ID_2 = М2.Город_ID_1) 
WHERE М1.Город_ID_1 != М2.Город_ID_2) М3
INNER JOIN #Маршруты_3 М4 ON М3.Город_ID_1 = М4.Город_ID_1 AND М3.Город_ID_2 = М4.Город_ID_2
WHERE М3.Расстояние < М4.Расстояние AND М3.Город_ID_1 > М3.Город_ID_2

/*8)Вывести суммарную длину маршрута по такому расписанию*/
SELECT Р1.Расписание_ID, (case when COUNT(М.Город_ID_1) != COUNT(Р1.Расписание_ID) then NULL else SUM(Расстояние) end) as Расстояние
FROM (Расписание Р1 INNER JOIN Расписание Р2 ON Р1.Номер + 1 = Р2.Номер AND Р1.Расписание_ID = Р2.Расписание_ID) 
LEFT JOIN #Маршруты_3 М ON Р1.Город_ID = М.Город_ID_1 AND Р2.Город_ID = М.Город_ID_2
GROUP BY Р1.Расписание_ID
