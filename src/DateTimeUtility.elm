module DateTimeUtility exposing (toUtcSlug, toUtcString)

import Time exposing (Month(..), toDay, toHour, toMonth, toYear, utc)


toUtcString : Time.Posix -> String
toUtcString time =
    monthString (Time.toMonth utc time)
        ++ "/"
        ++ String.fromInt (Time.toDay utc time)
        ++ ":"
        ++ String.fromInt (toHour utc time)
        ++ ":"
        ++ String.fromInt (Time.toMinute utc time)


toUtcSlug : String -> String -> Time.Posix -> String
toUtcSlug str1 str2 time =
    (toMonth utc time |> monthString)
        ++ "-"
        ++ String.fromInt (toDay utc time)
        ++ "-"
        ++ String.fromInt (toYear utc time)
        ++ "-"
        ++ str1
        ++ (toHour utc time |> String.fromInt)
        ++ str2


monthString : Time.Month -> String
monthString month =
    case month of
        Jan ->
            "1"

        Feb ->
            "2"

        Mar ->
            "3"

        Apr ->
            "4"

        May ->
            "5"

        Jun ->
            "6"

        Jul ->
            "7"

        Aug ->
            "8"

        Sep ->
            "9"

        Oct ->
            "10"

        Nov ->
            "11"

        Dec ->
            "12"
