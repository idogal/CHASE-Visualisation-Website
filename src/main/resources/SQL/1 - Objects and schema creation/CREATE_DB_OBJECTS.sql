USE [RE_Project]
GO
/****** Object:  UserDefinedFunction [dbo].[ConcatAuthors]    Script Date: 01/07/2017 15:17:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[ConcatAuthors](@PID BIGINT)
RETURNS VARCHAR(MAX)
AS 

BEGIN
	DECLARE @s NVARCHAR(MAX);
	--DECLARE @PID BIGINT;

	SELECT @s = COALESCE(@s + N', ', N'') + Authors.Author_Name
	FROM   Authors
	WHERE  Paper_Id = @PID;

	RETURN @S;
END

GO
/****** Object:  UserDefinedFunction [dbo].[GET_Authors_BC_MIN]    Script Date: 01/07/2017 15:17:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GET_Authors_BC_MIN] ()
	RETURNS @ABC_RESULTS TABLE (Author_ID_1 VARCHAR(100),  Author_Name_1 VARCHAR(1000), Author_ID_2 VARCHAR(100),  Author_Name_2 VARCHAR(1000), A_BC_Freq INT)
AS
BEGIN

	--DECLARE @ABC_RESULTS TABLE 
	--       (AID1 BIGINT,  ANAME1 VARCHAR(1000), AID2 BIGINT,  ANAME2 VARCHAR(1000), ABC_MIN INT);

	DECLARE C_CURSOR CURSOR 
	FOR
	  SELECT A.AID1, A.ANAME1, A.AID2, A.ANAME2, ABC_A1A2, A1_RANK
	  --SELECT A.ANAME1, A.ANAME1, A.ANAME2, A.ANAME2, ABC_A1A2, A1_RANK
	  FROM   ABC_All_Couples AS A;

	--DECLARE @AID1 BIGINT, @ANAME1 VARCHAR(1000)
	--	   ,@AID2 BIGINT, @ANAME2 VARCHAR(1000)
	--	   ,@C INT, @A1_RANK INT;

	DECLARE @AID1 VARCHAR(100), @ANAME1 VARCHAR(1000)
		   ,@AID2 VARCHAR(100), @ANAME2 VARCHAR(1000)
		   ,@C INT, @A1_RANK INT;

	OPEN C_CURSOR;
	FETCH NEXT FROM C_CURSOR INTO @AID1, @ANAME1, @AID2, @ANAME2, @C, @A1_RANK;

	WHILE (@@FETCH_STATUS <> -1)
	BEGIN
	
		IF NOT EXISTS (SELECT * FROM @ABC_RESULTS AS R WHERE R.Author_ID_1 = @AID1 AND R.Author_ID_2 = @AID2)
		BEGIN
			IF EXISTS (SELECT * FROM @ABC_RESULTS AS R WHERE R.Author_ID_1 = @AID2 AND R.Author_ID_2 = @AID1)
			BEGIN
				UPDATE @ABC_RESULTS 
				SET A_BC_Freq = A_BC_Freq + @C
				WHERE Author_ID_1 = @AID2 AND Author_ID_2 = @AID1;
			END
			ELSE
			BEGIN
				INSERT INTO @ABC_RESULTS
				VALUES (@AID1, @ANAME1, @AID2, @ANAME2, @C);
			END
		END

		--SELECT @AID1, @ANAME1, @AID2, @ANAME2, @C, @A1_RANK
		--WHERE NOT EXISTS (SELECT * FROM @ABC_RESULTS AS R WHERE R.AID1 = @AID1 AND R.AID2 = @AID2);

		FETCH NEXT FROM C_CURSOR INTO @AID1, @ANAME1, @AID2, @ANAME2, @C, @A1_RANK;
	END

	CLOSE C_CURSOR;
	DEALLOCATE C_CURSOR;

	RETURN;
END

GO
/****** Object:  Table [dbo].[Nums]    Script Date: 01/07/2017 15:17:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Nums](
	[n] [int] NOT NULL,
 CONSTRAINT [PK_n] PRIMARY KEY CLUSTERED 
(
	[n] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  UserDefinedFunction [dbo].[Format_Paper_For_Academic_API]    Script Date: 01/07/2017 15:17:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[Format_Paper_For_Academic_API](@Input_String VARCHAR(1000))
	RETURNS TABLE
AS

RETURN

--DECLARE @Input_String VARCHAR(1000) = 'Bridging knowledge distribution - The role of knowledge brokers in distributed software development teams';

WITH Each_Charachter_In_The_String (Charachter, Is_Charachter_Alphabetical)
AS
(
	SELECT SUBSTRING(@Input_String, Nums.n, 1), 
		   PATINDEX('[A-Z]', SUBSTRING(@Input_String, Nums.n, 1))
	FROM   Nums
	WHERE  Nums.n <= LEN(@Input_String)
)
,
    Charachters_And_Thier_Validity (Charachter, Is_Charachter_Valid)
AS
(
	SELECT Charachter = LOWER(Charachter)
		   ,
		   CASE 
		   WHEN Is_Charachter_Alphabetical = 0 AND Charachter = CHAR(32) THEN 1
		   WHEN Is_Charachter_Alphabetical = 1 THEN Is_Charachter_Alphabetical
		   ELSE 0
		   END
	FROM   Each_Charachter_In_The_String
),
    Replace_With_Spaces
AS
(
	SELECT Charachter =
	       CASE WHEN Is_Charachter_Valid = 0 THEN ' ' ELSE Charachter END
	FROM   Charachters_And_Thier_Validity
	--WHERE  Is_Charachter_Valid = 1
)
--SELECT Charachter, NTILE(2) OVER (PARTITION BY Charachter ORDER BY Charachter)
--FROM   Replace_With_Spaces

SELECT  [New_Value] = COALESCE(
    RTRIM(LTRIM(REPLACE(REPLACE(
    (
	SELECT CAST(Charachter AS CHAR(1)) AS [text()] 
	FROM   Replace_With_Spaces
	--WHERE  Is_Charachter_Valid = 1
	FOR XML PATH('')
	, TYPE).value('.[1]', 'VARCHAR(MAX)'), '  ', ' '), '  ', ' ')))
	, '');



GO
/****** Object:  Table [dbo].[Papers_Details]    Script Date: 01/07/2017 15:17:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Papers_Details](
	[Paper_Id] [bigint] NULL,
	[Paper_API_Id] [bigint] NOT NULL,
	[Paper_Order] [smallint] NULL,
	[Paper_Year] [char](4) NULL,
	[Paper_Date] [datetime] NULL,
	[Citations_Count] [int] NULL,
	[Est_Citations_Count] [int] NULL,
	[Display_Name] [varchar](1000) NULL,
	[Venue_Short_Name] [varchar](1000) NULL,
	[Venue_Full_Name] [varchar](1000) NULL,
	[DOI] [varchar](100) NULL,
	[Abstract] [varchar](max) NULL,
	[Abstract_Length] [int] NULL,
 CONSTRAINT [pk_Papers_Details_Paper_Id] PRIMARY KEY NONCLUSTERED 
(
	[Paper_API_Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Keywords]    Script Date: 01/07/2017 15:17:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Keywords](
	[Paper_Id] [bigint] NOT NULL,
	[Keyword_Value] [varchar](1000) NOT NULL,
 CONSTRAINT [pk_Keywords_paperid_value] PRIMARY KEY NONCLUSTERED 
(
	[Paper_Id] ASC,
	[Keyword_Value] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Fields_Of_Study]    Script Date: 01/07/2017 15:17:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Fields_Of_Study](
	[Paper_Id] [bigint] NOT NULL,
	[Field_Id] [bigint] NOT NULL,
	[Field_Name] [varchar](100) NULL,
 CONSTRAINT [pk_Fields_Of_Study_Paper_Id_Field_Id] PRIMARY KEY NONCLUSTERED 
(
	[Paper_Id] ASC,
	[Field_Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  View [dbo].[Fact_Keywords_And_Fields]    Script Date: 01/07/2017 15:17:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[Fact_Keywords_And_Fields]
AS

SELECT P.Paper_Id, P.Paper_API_Id, P.Paper_Year, W.Keyword_Value, F.Field_Name, 1 AS Amount, 
       COUNT(*) OVER (PARTITION BY P.Paper_Year, W.Keyword_Value, F.Field_Name) AS Year_KW_F_Count,
	   COUNT(*) OVER (PARTITION BY P.Paper_Year, W.Keyword_Value, F.Field_Name) * 100.000 / COUNT(*) OVER (PARTITION BY P.Paper_Year) AS Year_KW_F_Percent,
	   COUNT(*) OVER (PARTITION BY P.Paper_Year, W.Keyword_Value) AS Year_KW_Count,
	   COUNT(*) OVER (PARTITION BY P.Paper_Year, W.Keyword_Value) * 100.000 / COUNT(*) OVER (PARTITION BY P.Paper_Year) AS Year_KW_Percent,
	   COUNT(*) OVER (PARTITION BY P.Paper_Year, F.Field_Name) AS Year_F_Count,
	   COUNT(*) OVER (PARTITION BY P.Paper_Year, F.Field_Name) * 100.000 / COUNT(*) OVER (PARTITION BY P.Paper_Year) AS Year_F_Percent,
	   COUNT(*) OVER (PARTITION BY P.Paper_Year) AS Year_Count
FROM   Papers_Details AS P
       LEFT OUTER JOIN Keywords AS W
	     ON (P.Paper_API_Id = W.Paper_Id)
       LEFT OUTER JOIN Fields_Of_Study AS F
	     ON (P.Paper_API_Id = F.Paper_Id)
WHERE  P.Paper_Order = 1

GO
/****** Object:  View [dbo].[Dim_Keywords]    Script Date: 01/07/2017 15:17:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[Dim_Keywords]
AS
	SELECT DISTINCT K.Keyword_Value
	FROM Keywords AS K

GO
/****** Object:  View [dbo].[Dim_Fields_Of_Study]    Script Date: 01/07/2017 15:17:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[Dim_Fields_Of_Study]
AS
	SELECT DISTINCT F.Field_Name
	FROM Fields_Of_Study AS F

GO
/****** Object:  Table [dbo].[Keywords_With_Similarity]    Script Date: 01/07/2017 15:17:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Keywords_With_Similarity](
	[Keyword_1] [varchar](1000) NOT NULL,
	[Keyword_2] [varchar](1000) NOT NULL,
	[Sim_Levenshtein] [float] NULL,
	[Sim_JaroWinkler] [float] NULL
) ON [PRIMARY]

GO
/****** Object:  View [dbo].[Data_Keywords_Summary]    Script Date: 01/07/2017 15:17:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[Data_Keywords_Summary] 
AS

WITH Papers_Keywords
  AS
(
	SELECT PD.Paper_Year,
	       [Keyword_Value] = 
		   ISNULL(
		   (SELECT TOP (1) Keyword_1 FROM Keywords_With_Similarity AS K_Sim 
		    WHERE (K.Keyword_Value = K_Sim.Keyword_2) ORDER BY K_Sim.Sim_JaroWinkler DESC), Keyword_Value)
	FROM   Papers_Details AS PD
		   JOIN [Keywords] AS K
			 ON (PD.Paper_API_Id = K.Paper_Id)
)
, GRP
  AS
(
	SELECT Paper_Year, Keyword_Value, COUNT(*) AS Count_Yearly, 
	(SELECT COUNT(*) FROM Papers_Keywords) AS Count_Total,
	100.000 * COUNT(*) / (SELECT COUNT(*) FROM Papers_Keywords) AS PCT_Total,
	100.000 * COUNT(*) / COUNT(*) OVER (PARTITION BY Paper_Year) AS PCT_Yearly
	FROM   Papers_Keywords
	GROUP BY Paper_Year, Keyword_Value
)
SELECT * 
FROM   GRP


GO
/****** Object:  Table [dbo].[Papers_References]    Script Date: 01/07/2017 15:17:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Papers_References](
	[Paper_ID] [bigint] NOT NULL,
	[Reference_ID] [bigint] NOT NULL,
	[Ref_JSON_Info] [varchar](max) NULL,
 CONSTRAINT [pk_Papers_References] PRIMARY KEY NONCLUSTERED 
(
	[Paper_ID] ASC,
	[Reference_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  View [dbo].[Papers_Bibligraphical_Coupling]    Script Date: 01/07/2017 15:17:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[Papers_Bibligraphical_Coupling]
AS

WITH Refs_Cartesian_Product
 AS
(
	SELECT R1.Paper_ID AS PID1
		 , R2.Paper_ID AS PID2
		 , R1.Reference_ID AS RefID1
		 , R2.Reference_ID AS RefID2
	FROM   [Papers_References] AS R1
		   CROSS JOIN [Papers_References] AS R2
	WHERE  R1.Paper_ID <> R2.Paper_ID
		   AND R1.Reference_ID = R2.Reference_ID
		   AND EXISTS (SELECT * FROM [Papers_Details] AS P WHERE P.Paper_API_Id = R1.Paper_ID AND P.Paper_Order = 1)
		   AND EXISTS (SELECT * FROM [Papers_Details] AS P WHERE P.Paper_API_Id = R2.Paper_ID AND P.Paper_Order = 1)
),
 Coupling
AS
(
	SELECT RR.PID1, PD1.Display_Name AS P1_DN, RR.PID2, PD2.Display_Name AS P2_DN, RR.RefID1, RR.RefID2
	FROM   Refs_Cartesian_Product AS RR
		   INNER JOIN dbo.Papers_Details AS PD1
			 ON (RR.PID1 = PD1.Paper_API_Id)
		   INNER JOIN dbo.Papers_Details AS PD2
			 ON (RR.PID2 = PD2.Paper_API_Id)
)
SELECT BC.PID1, BC.PID2, COUNT(*) AS Bibligraphical_Coupling
FROM   Coupling AS BC
GROUP BY BC.PID1, BC.PID2


GO
/****** Object:  Table [dbo].[Authors]    Script Date: 01/07/2017 15:17:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Authors](
	[Paper_Id] [bigint] NOT NULL,
	[Author_Id] [bigint] NOT NULL,
	[Author_Name] [varchar](100) NULL,
	[Author_Position] [int] NULL,
	[Affiliation_Id] [bigint] NULL,
	[Affiliation_Name] [varchar](100) NULL,
 CONSTRAINT [pk_Authors_Author_Id_value] PRIMARY KEY NONCLUSTERED 
(
	[Paper_Id] ASC,
	[Author_Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  View [dbo].[ABC_All_Couples]    Script Date: 01/07/2017 15:17:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW [dbo].[ABC_All_Couples]
AS

WITH 
 Authors_Refs
 AS
(
	SELECT A.Paper_Id, R.Reference_ID, A.Author_Id, A.Author_Name
	FROM   [dbo].[Papers_References] AS R
		   INNER JOIN [dbo].[Authors] AS A
			 ON (A.Paper_Id = R.Paper_ID)
	WHERE  EXISTS (SELECT * FROM [Papers_Details] AS P WHERE P.Paper_API_Id = R.Paper_ID AND P.Paper_Order = 1 AND P.Paper_Year <> '2017')
)
, Authors_Refs_With_Exclution (Ref_ID, AID1, ANAME1, AID2, ANAME2)
  AS
(
	SELECT AR1.Reference_ID, AR1.Author_Id, AR1.Author_Name, AR2.Author_Id, AR2.Author_Name
	FROM   Authors_Refs AS AR1
		   INNER JOIN Authors_Refs AS AR2
			 ON (AR1.Reference_ID = AR2.Reference_ID 
				 AND AR1.Author_Id <> AR2.Author_Id 
				 AND AR1.Paper_Id <> AR2.Paper_Id)
)
, Authors_Reds_Min_Freq (Ref_ID, AID1, ANAME1, AID2, ANAME2, Freq1, Freq2, Min_Freq)
  AS
(
	SELECT AR.Ref_ID, AR.AID1, AR.ANAME1, AR.AID2, AR.ANAME2, F1.Freq, F2.Freq
		  ,Min_Num =
			(SELECT MIN(Nums.N) 
			 FROM (
			 SELECT F1.Freq AS N UNION ALL SELECT F2.Freq) AS Nums)
	FROM   Authors_Refs_With_Exclution AS AR
		   CROSS APPLY 
		   (
			SELECT COUNT(*) AS Freq
			FROM   [dbo].[Papers_References] AS R
					INNER JOIN [dbo].[Authors] AS A
						ON (A.Paper_Id = R.Paper_ID)
			WHERE  R.Reference_ID = AR.Ref_ID
				   AND A.Author_Id = AR.AID1
				   AND NOT EXISTS (SELECT * FROM [dbo].[Authors] AS A2 
								   WHERE A2.Author_Id = AR.AID2 AND A2.Paper_Id = A.Paper_Id)
		   ) AS F1
		   CROSS APPLY 
		   (
			SELECT COUNT(*) AS Freq
			FROM   [dbo].[Papers_References] AS R
					INNER JOIN [dbo].[Authors] AS A
						ON (A.Paper_Id = R.Paper_ID)
			WHERE  R.Reference_ID = AR.Ref_ID
				   AND A.Author_Id = AR.AID2
				   AND NOT EXISTS (SELECT * FROM [dbo].[Authors] AS A2 
								   WHERE A2.Author_Id = AR.AID1 AND A2.Paper_Id = A.Paper_Id)
		   ) AS F2
)
SELECT AID1, ANAME1, AID2, ANAME2, SUM(Min_Freq) AS ABC_A1A2
      ,ROW_NUMBER() OVER (PARTITION BY AID1 ORDER BY AID1) AS RN
	  ,DENSE_RANK() OVER (ORDER BY AID1) AS A1_RANK
FROM   Authors_Reds_Min_Freq
GROUP BY AID1, ANAME1, AID2, ANAME2




GO
/****** Object:  View [dbo].[Authors_Pairs]    Script Date: 01/07/2017 15:17:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW [dbo].[Authors_Pairs]
AS

WITH DATA_RANKED
AS
(
SELECT A1.Author_Name AS ANAME1, A2.Author_Name AS ANAME2
      ,DENSE_RANK() OVER (ORDER BY A1.Author_Name) AS DR
FROM   Authors AS A1
       CROSS JOIN Authors AS A2
WHERE  A1.Author_Name <> A2.Author_Name
       AND EXISTS (SELECT * FROM Papers_Details AS PD WHERE PD.Paper_API_Id = A1.Paper_Id AND PD.Paper_Order = 1)
	   AND EXISTS (SELECT * FROM Papers_Details AS PD WHERE PD.Paper_API_Id = A2.Paper_Id AND PD.Paper_Order = 1)
) 
SELECT DISTINCT D1.ANAME1, D1.ANAME2
FROM   DATA_RANKED AS D1
WHERE  NOT EXISTS (SELECT * FROM DATA_RANKED AS D2 WHERE D2.ANAME2 = D1.ANAME1 AND D2.ANAME1 = D1.ANAME2 AND D2.DR > D1.DR)




GO
/****** Object:  View [dbo].[Authors_References]    Script Date: 01/07/2017 15:17:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[Authors_References]
AS	
	SELECT R.Paper_ID, R.Reference_ID, A.Author_Name
	FROM   [dbo].[Papers_References] AS R INNER JOIN [dbo].[Authors] AS A ON (A.Paper_Id = R.Paper_ID)
	WHERE  EXISTS (SELECT * FROM [Papers_Details] AS P WHERE P.Paper_API_Id = R.Paper_ID AND P.Paper_Order = 1)

GO
/****** Object:  View [dbo].[Authors_Proccessed]    Script Date: 01/07/2017 15:17:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[Authors_Proccessed]
AS

WITH A
AS
(
	SELECT DISTINCT A.Author_Name
	FROM   Authors AS A
	WHERE EXISTS (SELECT * FROM Papers_Details AS PD WHERE PD.Paper_API_Id = A.Paper_Id AND PD.Paper_Order = 1)
)
SELECT * 
FROM   A
       CROSS APPLY
	   (
	   SELECT  STUFF(REPLACE(COALESCE(
       (
	   SELECT ',' + AA2.Affiliation_Name AS [text()]
	   FROM  
	   (
	   SELECT Author_Name, Affiliation_Name
	   FROM 
	       (
		   SELECT DISTINCT A2.Author_Name, ISNULL(A2.Affiliation_Name, '') AS Affiliation_Name
		   FROM   Authors AS A2
		   WHERE EXISTS (SELECT * FROM Papers_Details AS PD WHERE PD.Paper_API_Id = A2.Paper_Id AND PD.Paper_Order = 1)
		   ) AS AA
	   WHERE A.Author_Name = AA.Author_Name
	   ) AS AA2
       FOR XML PATH('')
	   , TYPE).value('.[1]', 'VARCHAR(MAX)'), ''),',,',','), 1, 1, '')
	   ) AS Affilliation (Aff_Name)

GO
/****** Object:  View [dbo].[CHASE_Papers__Papers_Details]    Script Date: 01/07/2017 15:17:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[CHASE_Papers__Papers_Details]
AS

SELECT Paper_Id, Paper_API_Id, Paper_Order, PD.Paper_Year, PD.Paper_Date, PD.Citations_Count, PD.Est_Citations_Count, PD.Display_Name
     , PD.Venue_Short_Name, PD.Venue_Full_Name, PD.DOI, PD.Abstract, PD.Abstract_Length
	 , KW.Keywords, F.Fields, A.Authors
FROM   Papers_Details AS PD
       CROSS APPLY
	   (
	    SELECT STUFF(
		(
		SELECT ', ' + KW.Keyword_Value AS [text()]
		FROM   Keywords AS KW
		WHERE  KW.Paper_Id = PD.Paper_API_Id
		FOR XML PATH('') 
		, TYPE).value('.[1]', 'VARCHAR(MAX)'), 1, 2, '')
	   ) AS KW (Keywords)
       CROSS APPLY
	   (
	    SELECT STUFF(
		(
		SELECT ', ' + F.Field_Name AS [text()]
		FROM   Fields_Of_Study AS F
		WHERE  F.Paper_Id = PD.Paper_API_Id
		FOR XML PATH('') 
		, TYPE).value('.[1]', 'VARCHAR(MAX)'), 1, 2, '')
	   ) AS F (Fields)
       CROSS APPLY
	   (
	    SELECT STUFF(
		(
		SELECT ', ' + A.Author_Name AS [text()]
		FROM   Authors AS A
		WHERE  A.Paper_Id = PD.Paper_API_Id
		FOR XML PATH('') 
		, TYPE).value('.[1]', 'VARCHAR(MAX)'), 1, 2, '')
	   ) AS A (Authors)
WHERE  Paper_Order = 1

GO
/****** Object:  View [dbo].[Fact_Keywords]    Script Date: 01/07/2017 15:17:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[Fact_Keywords]
AS

SELECT P.Paper_Id, P.Paper_API_Id, P.Paper_Year, W.Keyword_Value, 1 AS Amount, 
       COUNT(*) OVER (PARTITION BY P.Paper_Year, W.Keyword_Value) AS Year_KW_Count,
	   COUNT(*) OVER (PARTITION BY P.Paper_Year, W.Keyword_Value) * 100.000 / COUNT(*) OVER (PARTITION BY P.Paper_Year) AS Year_KW_Percent,
	   COUNT(*) OVER (PARTITION BY P.Paper_Year) AS Year_Count
FROM   Papers_Details AS P
       LEFT OUTER JOIN Keywords AS W
	     ON (P.Paper_API_Id = W.Paper_Id)
WHERE  P.Paper_Order = 1


GO
/****** Object:  UserDefinedFunction [dbo].[Generate_Nums]    Script Date: 01/07/2017 15:17:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/* Created by:	Ido Gal, 01/2014											*/
/* Notes:		This script generates the numbers beween 0 and 1000000.		*/
/* Usage:		SELECT * FROM dbo.Generate_Nums (10000) ORDER BY Number ASC	*/
/*																			*/
/*				Useful for DATEADD join operation etc.						*/

CREATE FUNCTION [dbo].[Generate_Nums](@Limit INT)
	RETURNS TABLE
AS

	RETURN
	(
		WITH	DigitsCTE AS
		(
			SELECT	0 AS 'Digit'	UNION ALL
			SELECT	1				UNION ALL
			SELECT	2				UNION ALL
			SELECT	3				UNION ALL
			SELECT	4				UNION ALL
			SELECT	5				UNION ALL
			SELECT	6				UNION ALL
			SELECT	7				UNION ALL
			SELECT	8				UNION ALL
			SELECT	9	
		) 
		, 
				NumbersCTE AS
		(
			SELECT	Number	=	Millions.Digit * 1000000 + HundredThousands.Digit * 100000	+ TenThousands.Digit * 10000		+ Thousands.Digit * 1000 +
								Hundreds.Digit * 100			+ Tenths.Digit * 10					+ Digits.Digit * 1
			FROM	DigitsCTE AS Millions
					CROSS JOIN	DigitsCTE AS HundredThousands
					CROSS JOIN	DigitsCTE AS TenThousands
					CROSS JOIN	DigitsCTE AS Thousands
					CROSS JOIN	DigitsCTE AS Hundreds
					CROSS JOIN	DigitsCTE AS Tenths
					CROSS JOIN	DigitsCTE AS Digits
		)
		SELECT	NumbersCTE.Number
		FROM	NumbersCTE
		WHERE	(NumbersCTE.Number <= @Limit AND NumbersCTE.Number > 0)
	);

GO
/****** Object:  Table [dbo].[Citation_Contexts]    Script Date: 01/07/2017 15:17:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Citation_Contexts](
	[Paper_Id] [bigint] NOT NULL,
	[Citation_ID] [bigint] NOT NULL,
	[Citation_Value] [varchar](8000) NULL,
 CONSTRAINT [pk_Citation_Contexts] PRIMARY KEY NONCLUSTERED 
(
	[Paper_Id] ASC,
	[Citation_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[DIMTIME]    Script Date: 01/07/2017 15:17:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DIMTIME](
	[TIME_YEAR] [char](4) NULL,
	[TIME_ID] [int] IDENTITY(1,1) NOT NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Inverted_Abstract]    Script Date: 01/07/2017 15:17:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Inverted_Abstract](
	[Paper_Id] [bigint] NULL,
	[Word_Value] [varchar](100) NULL,
	[Work_Checksum] [int] NULL,
	[Word_Positions] [varchar](8000) NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Papers_Academic_Info]    Script Date: 01/07/2017 15:17:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Papers_Academic_Info](
	[Paper_ID] [bigint] NULL,
	[Paper_Name] [varchar](1000) NULL,
	[JSON_Acedemic_Info] [varchar](8000) NULL,
	[Extended_Academic_Info] [nvarchar](max) NULL,
	[References_JSON_Info] [varchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Papers_List]    Script Date: 01/07/2017 15:17:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Papers_List](
	[ID] [float] NULL,
	[Conference_Year] [float] NULL,
	[Paper_Name] [nvarchar](255) NULL
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[Authors]  WITH CHECK ADD  CONSTRAINT [FK_Authors_paperid] FOREIGN KEY([Paper_Id])
REFERENCES [dbo].[Papers_Details] ([Paper_API_Id])
GO
ALTER TABLE [dbo].[Authors] CHECK CONSTRAINT [FK_Authors_paperid]
GO
ALTER TABLE [dbo].[Citation_Contexts]  WITH CHECK ADD  CONSTRAINT [FK_Citation_Contexts] FOREIGN KEY([Paper_Id])
REFERENCES [dbo].[Papers_Details] ([Paper_API_Id])
GO
ALTER TABLE [dbo].[Citation_Contexts] CHECK CONSTRAINT [FK_Citation_Contexts]
GO
ALTER TABLE [dbo].[Fields_Of_Study]  WITH CHECK ADD  CONSTRAINT [FK_Fields_Of_Study_paperid] FOREIGN KEY([Paper_Id])
REFERENCES [dbo].[Papers_Details] ([Paper_API_Id])
GO
ALTER TABLE [dbo].[Fields_Of_Study] CHECK CONSTRAINT [FK_Fields_Of_Study_paperid]
GO
ALTER TABLE [dbo].[Inverted_Abstract]  WITH CHECK ADD  CONSTRAINT [FK_Inverted_Abstract] FOREIGN KEY([Paper_Id])
REFERENCES [dbo].[Papers_Details] ([Paper_API_Id])
GO
ALTER TABLE [dbo].[Inverted_Abstract] CHECK CONSTRAINT [FK_Inverted_Abstract]
GO
ALTER TABLE [dbo].[Keywords]  WITH CHECK ADD  CONSTRAINT [FK_Keywords_paperid] FOREIGN KEY([Paper_Id])
REFERENCES [dbo].[Papers_Details] ([Paper_API_Id])
GO
ALTER TABLE [dbo].[Keywords] CHECK CONSTRAINT [FK_Keywords_paperid]
GO
ALTER TABLE [dbo].[Papers_References]  WITH CHECK ADD  CONSTRAINT [FK_Papers_References] FOREIGN KEY([Paper_ID])
REFERENCES [dbo].[Papers_Details] ([Paper_API_Id])
GO
ALTER TABLE [dbo].[Papers_References] CHECK CONSTRAINT [FK_Papers_References]
GO
/****** Object:  StoredProcedure [dbo].[ConcatRowsWithDelimiter]    Script Date: 01/07/2017 15:17:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE  [dbo].[ConcatRowsWithDelimiter] 
(
	@TableName	VARCHAR(100),
	@Column		VARCHAR(100),
	@OrderBy	VARCHAR(200)	= NULL,
	@DELIMITER	VARCHAR(10)		= ',',
	@ReturnString VARCHAR(MAX) OUTPUT
)

AS

DECLARE @CMD NVARCHAR(MAX);

SET @CMD = 
'SELECT		TABLE_ROWS	= ' + ISNULL(@Column,1) + CHAR(10) + 
'			, RowNumber =	ROW_NUMBER() OVER (ORDER BY ' + ISNULL(@OrderBy,@Column) + ' )' + CHAR(10) + 
'FROM		' + @TableName 

DECLARE @TableRows TABLE
(
	TABLE_ROWS	VARCHAR(MAX),
	RowNumber	INT				PRIMARY KEY
);


INSERT INTO @TableRows (TABLE_ROWS, RowNumber)
	EXECUTE sp_executesql @CMD;


WITH CREATE_HTML_TABLE_ROWS_CTE
AS
(
	SELECT	RowNumber	= TR.RowNumber, 
			String		= TR.TABLE_ROWS
	FROM	@TableRows AS TR
	WHERE	TR.RowNumber = 1

	UNION ALL

	SELECT	RowNumber	= [Next].RowNumber,
			String		= Prev.String + @DELIMITER + [Next].TABLE_ROWS
	FROM	CREATE_HTML_TABLE_ROWS_CTE AS Prev
			JOIN @TableRows AS [Next]
				ON (Prev.RowNumber + 1 = [Next].RowNumber)
)
SELECT	@ReturnString = '''' + String + ''''
FROM	CREATE_HTML_TABLE_ROWS_CTE AS HR
WHERE	HR.RowNumber = (SELECT MAX(RowNumber) FROM @TableRows)
OPTION	(MAXRECURSION 0);


GO
/****** Object:  StoredProcedure [dbo].[Send_HttpGet_Request_With_AuthorizationHeader]    Script Date: 01/07/2017 15:17:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Send_HttpGet_Request_With_AuthorizationHeader]
(
	@Url_EndPoint VARCHAR(512),
	--@Auth_Token   VARCHAR(8000),
	@Output_Text  VARCHAR(8000) OUTPUT
)
AS
BEGIN

	--SET @Url_EndPoint = 'http://webapi.mymarketing.co.il/api/groups';
	--SET @Auth_Token = '0X6F79970F29A47ABD11A86E7B380AAFDF841A62BE8A71F63F2A700A7B0B419C67B816E43E17F86CD432A7037F7EB149FA';

	--DECLARE @Output_Text VARCHAR(8000)
    DECLARE @win int;
    DECLARE @hr  int;

	EXECUTE @hr = sp_OACreate 'WinHttp.WinHttpRequest.5.1', @win OUTPUT;
	IF (@hr <> 0) 
	   EXECUTE sp_OAGetErrorInfo @win;

	EXECUTE @hr = sp_OAMethod @win,  'Open', NULL, 'GET', @Url_EndPoint, 'false';
	IF (@hr <> 0) 
	   EXECUTE sp_OAGetErrorInfo @win;

	--DECLARE @Auth_Header_Value VARCHAR(8000);
	--SET @Auth_Header_Value = 'Basic ' + @Auth_Token;

	--EXECUTE @hr = sp_OAMethod @win, 'setRequestHeader', NULL, 'Authorization', @Auth_Header_Value;
	--IF (@hr <> 0) 
	--   EXECUTE sp_OAGetErrorInfo @win;

	EXECUTE @hr = sp_OAMethod @win, 'Send';
	IF (@hr <> 0)
	   EXECUTE sp_OAGetErrorInfo @win;

	EXECUTE @hr = sp_OAGetProperty @win, 'ResponseText', @Output_Text OUTPUT;
	IF (@hr <> 0) 
	   EXECUTE sp_OAGetErrorInfo @win;

	EXECUTE @hr = sp_OADestroy @win ;
	IF (@hr <> 0) 
	   EXECUTE sp_OAGetErrorInfo @win;

	--PRINT @Output_Text;

	RETURN @Output_Text;

END


GO
