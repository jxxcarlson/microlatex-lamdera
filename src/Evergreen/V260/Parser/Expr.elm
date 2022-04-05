module Evergreen.V260.Parser.Expr exposing (..)

import Evergreen.V260.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V260.Parser.Meta.Meta
    | Text String Evergreen.V260.Parser.Meta.Meta
    | Verbatim String String Evergreen.V260.Parser.Meta.Meta
