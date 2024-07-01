/*
Copyright 2023 Darling Data, LLC
https://www.erikdarlingdata.com/
This will set up two views:
 * dbo.WhoIsActive: a UNION ALL of all tables that match the WhoIsActive_YYYYMMDD formaty
 * dbo.WhoIsActive_blocking: a recursive CTE that walks blocking chains in the above view
If you need to get or update sp_WhoIsActive:
https://github.com/amachanic/sp_whoisactive
(C) 2007-2022, Adam Machanic
*/

  WITH b AS
        (
            SELECT
                l =
                    CONVERT
                    (
                        varchar(1000),
                        REPLICATE
                        (
                            ' ',
                            4 -
                            LEN
                            (
                                CONVERT
                                (
                                    varchar(1000),
                                    wia.session_id
                                )
                            )
                        ) +
                          CONVERT
                          (
                              varchar(1000),
                              wia.session_id
                          )
                    ),
                wia.collection_time,
              --  wia.[dd hh:mm:ss.mss],
                wia.sql_text,
                wia.sql_command,
                wia.login_name,
                wia.wait_info,
                wia.session_id,
                wia.blocking_session_id,
                --wia.blocked_session_count,
                --wia.implicit_tran,
                wia.status,
                wia.open_tran_count,
                wia.query_plan,
                wia.additional_info
            FROM dbo.History_WhoIsActive AS wia
            WHERE (wia.blocking_session_id IS NULL
                    OR  wia.blocking_session_id = wia.session_id)
            AND   EXISTS
                  (
                      SELECT
                          1/0
                      FROM dbo.History_WhoIsActive AS wia2
                      WHERE wia2.blocking_session_id = wia.session_id
                      AND   wia2.collection_time = wia.collection_time
                      AND   wia2.blocking_session_id <> wia2.session_id
                  )
            UNION ALL
            SELECT
                l =
                    CONVERT
                    (
                        varchar(1000),
                        REPLICATE
                        (
                            ' ',
                            4 -
                              LEN
                              (
                                  CONVERT(varchar(1000),
                                  wia.session_id
                              )
                        )
                    ) +
                      CONVERT
                      (
                          varchar(1000),
                          wia.session_id
                      )
                    ),
                wia.collection_time,
              --  wia.[dd hh:mm:ss.mss],
                wia.sql_text,
                wia.sql_command,
                wia.login_name,
                wia.wait_info,
                wia.session_id,
                wia.blocking_session_id,
                --wia.blocked_session_count,
                --wia.implicit_tran,
                wia.status,
                wia.open_tran_count,
                wia.query_plan,
                wia.additional_info
            FROM dbo.History_WhoIsActive AS wia
            INNER JOIN b AS b
              ON  wia.blocking_session_id = b.session_id
              AND b.collection_time = wia.collection_time
            WHERE wia.blocking_session_id IS NOT NULL
            AND   wia.blocking_session_id <> wia.session_id
        )
        SELECT TOP (9223372036854775807)
            --b.[dd hh:mm:ss.mss],
            blocking =
                '|--->' +
                REPLICATE
                (
                    ' |---> ',
                    LEN(b.l) / 4 - 1
                ) +
                CASE
                    WHEN b.blocking_session_id IS NULL
                    THEN ' Lead SPID: '
                    ELSE '|---> Blocked SPID: '
                END +
                CONVERT
                (
                    varchar(10),
                    b.session_id
                ) +
                ' ' +
                CONVERT
                (
                    varchar(30),
                    b.collection_time
                ),
            b.wait_info,
            b.sql_text,
            b.sql_command,
            b.query_plan,
            b.additional_info,
            b.session_id,
            b.blocking_session_id,
            --b.blocked_session_count,
            --b.implicit_tran,
            b.status,
            b.open_tran_count,
            b.login_name,
            b.collection_time
        FROM b AS b
        ORDER BY
            b.collection_time desc
          --,  b.blocked_session_count DESC;