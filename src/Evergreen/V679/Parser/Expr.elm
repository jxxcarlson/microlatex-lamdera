module Evergreen.V679.Parser.Expr exposing (..)

import Evergreen.V679.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V679.Parser.Meta.Meta
    | Text String Evergreen.V679.Parser.Meta.Meta
    | Verbatim String String Evergreen.V679.Parser.Meta.Meta
