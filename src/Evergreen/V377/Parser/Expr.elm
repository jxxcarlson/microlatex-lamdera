module Evergreen.V377.Parser.Expr exposing (..)

import Evergreen.V377.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V377.Parser.Meta.Meta
    | Text String Evergreen.V377.Parser.Meta.Meta
    | Verbatim String String Evergreen.V377.Parser.Meta.Meta
