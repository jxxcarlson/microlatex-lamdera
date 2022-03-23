module Evergreen.V152.Parser.Expr exposing (..)

import Evergreen.V152.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V152.Parser.Meta.Meta
    | Text String Evergreen.V152.Parser.Meta.Meta
    | Verbatim String String Evergreen.V152.Parser.Meta.Meta
