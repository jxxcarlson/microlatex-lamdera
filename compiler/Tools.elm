module Tools exposing (..)


debugLog2 : String -> (a -> b) -> a -> a
debugLog2 label f a =
    Debug.log (label ++ ":: " ++ Debug.toString (f a)) a
