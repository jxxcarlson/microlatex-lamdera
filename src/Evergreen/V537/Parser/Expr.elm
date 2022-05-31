module Evergreen.V537.Parser.Expr exposing (..)

import Evergreen.V537.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V537.Parser.Meta.Meta
    | Text String Evergreen.V537.Parser.Meta.Meta
    | Verbatim String String Evergreen.V537.Parser.Meta.Meta
