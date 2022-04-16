module Evergreen.V391.Parser.Expr exposing (..)

import Evergreen.V391.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V391.Parser.Meta.Meta
    | Text String Evergreen.V391.Parser.Meta.Meta
    | Verbatim String String Evergreen.V391.Parser.Meta.Meta
