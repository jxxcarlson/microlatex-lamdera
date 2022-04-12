module Evergreen.V360.Parser.Expr exposing (..)

import Evergreen.V360.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V360.Parser.Meta.Meta
    | Text String Evergreen.V360.Parser.Meta.Meta
    | Verbatim String String Evergreen.V360.Parser.Meta.Meta
