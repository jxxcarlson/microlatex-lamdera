module Tools exposing (blue, cyan, debugLog1, debugLog2, forklogBlue, forklogCyan, forklogRed, forklogYellow)

import Console


forklogRed label width f a =
    forklog_ Console.white Console.bgRed label width f a


forklogYellow label width f a =
    forklog_ Console.black Console.bgYellow label width f a


forklogCyan label width f a =
    forklog_ Console.black Console.bgCyan label width f a


forklogBlue label width f a =
    forklog_ Console.white Console.bgBlue label width f a



--forklog_ fg bg label width f a =
--    let
--        _ =
--            Debug.log (coloredLabel fg bg label width) (f a)
--    in
--    a


forklog_ fg bg label width f a =
    a


coloredLabel fg bg label width =
    let
        n =
            String.length label

        padding =
            String.repeat (width - n) " "
    in
    label |> (\x -> " " ++ x ++ padding) |> bg |> fg


blue : String -> Int -> String
blue label width =
    let
        n =
            String.length label

        padding =
            String.repeat (width - n) " "
    in
    label |> (\x -> " " ++ x ++ padding) |> Console.bgBlue |> Console.white


cyan label width =
    let
        n =
            String.length label

        padding =
            String.repeat (width - n) " "
    in
    label |> (\x -> " " ++ x ++ padding) |> Console.bgCyan |> Console.black


debugLog1 : String -> a -> a
debugLog1 label a =
    --Debug.log (label |> Console.bgBlue |> Console.white) a
    a


debugLog2 : String -> (a -> b) -> a -> a
debugLog2 label f a =
    --Debug.log (label ++ ":: " ++ Debug.toString (f a) |> Console.bgCyan |> Console.black) a
    a



--a
