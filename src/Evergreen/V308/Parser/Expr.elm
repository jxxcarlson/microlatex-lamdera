module Evergreen.V308.Parser.Expr exposing (..)

import Evergreen.V308.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V308.Parser.Meta.Meta
    | Text String Evergreen.V308.Parser.Meta.Meta
    | Verbatim String String Evergreen.V308.Parser.Meta.Meta
