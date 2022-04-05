module Evergreen.V259.Parser.Expr exposing (..)

import Evergreen.V259.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V259.Parser.Meta.Meta
    | Text String Evergreen.V259.Parser.Meta.Meta
    | Verbatim String String Evergreen.V259.Parser.Meta.Meta
