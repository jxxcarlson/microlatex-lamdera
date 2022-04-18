module Evergreen.V405.Parser.Expr exposing (..)

import Evergreen.V405.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V405.Parser.Meta.Meta
    | Text String Evergreen.V405.Parser.Meta.Meta
    | Verbatim String String Evergreen.V405.Parser.Meta.Meta
