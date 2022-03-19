module Tools exposing (blue, cyan, debugLog1, debugLog2)

import Console


blue label =
    label |> Console.bgBlue |> Console.white


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
