module Evergreen.V494.Parser.Expr exposing (..)

import Evergreen.V494.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V494.Parser.Meta.Meta
    | Text String Evergreen.V494.Parser.Meta.Meta
    | Verbatim String String Evergreen.V494.Parser.Meta.Meta
