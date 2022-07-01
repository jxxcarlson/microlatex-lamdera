module Evergreen.V681.Parser.Expr exposing (..)

import Evergreen.V681.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V681.Parser.Meta.Meta
    | Text String Evergreen.V681.Parser.Meta.Meta
    | Verbatim String String Evergreen.V681.Parser.Meta.Meta
