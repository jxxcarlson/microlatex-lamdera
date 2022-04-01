module Evergreen.V205.Parser.Expr exposing (..)

import Evergreen.V205.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V205.Parser.Meta.Meta
    | Text String Evergreen.V205.Parser.Meta.Meta
    | Verbatim String String Evergreen.V205.Parser.Meta.Meta
