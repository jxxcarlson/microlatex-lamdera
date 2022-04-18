module Evergreen.V410.Parser.Expr exposing (..)

import Evergreen.V410.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V410.Parser.Meta.Meta
    | Text String Evergreen.V410.Parser.Meta.Meta
    | Verbatim String String Evergreen.V410.Parser.Meta.Meta
