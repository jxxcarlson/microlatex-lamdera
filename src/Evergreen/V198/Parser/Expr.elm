module Evergreen.V198.Parser.Expr exposing (..)

import Evergreen.V198.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V198.Parser.Meta.Meta
    | Text String Evergreen.V198.Parser.Meta.Meta
    | Verbatim String String Evergreen.V198.Parser.Meta.Meta
