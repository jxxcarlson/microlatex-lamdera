module DateTimeUtility exposing (toString, toStringWithYear)

import Time


toString : Time.Zone -> Time.Posix -> String
toString zone time =
    monthString (Time.toMonth zone time)
        ++ "/"
        ++ (String.fromInt (Time.toDay zone time) |> String.padLeft 2 '0')
        --++ "/"
        --++ String.fromInt (Time.toYear zone time)
        ++ ", "
        ++ (String.fromInt (Time.toHour zone time) |> String.padLeft 2 '0')
        ++ ":"
        ++ (String.fromInt (Time.toMinute zone time) |> String.padLeft 2 '0')


toStringWithYear : Time.Zone -> Time.Posix -> String
toStringWithYear zone time =
    monthString (Time.toMonth zone time)
        ++ "/"
        ++ (String.fromInt (Time.toDay zone time) |> String.padLeft 2 '0')
        ++ "/"
        ++ String.fromInt (Time.toYear zone time)
        ++ ", "
        ++ (String.fromInt (Time.toHour zone time) |> String.padLeft 2 '0')
        ++ ":"
        ++ (String.fromInt (Time.toMinute zone time) |> String.padLeft 2 '0')



--


monthString : Time.Month -> String
monthString month =
    case month of
        Time.Jan ->
            "1"

        Time.Feb ->
            "2"

        Time.Mar ->
            "3"

        Time.Apr ->
            "4"

        Time.May ->
            "5"

        Time.Jun ->
            "6"

        Time.Jul ->
            "7"

        Time.Aug ->
            "8"

        Time.Sep ->
            "9"

        Time.Oct ->
            "10"

        Time.Nov ->
            "11"

        Time.Dec ->
            "12"
