module Evergreen.V686.Parser.Expr exposing (..)

import Evergreen.V686.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V686.Parser.Meta.Meta
    | Text String Evergreen.V686.Parser.Meta.Meta
    | Verbatim String String Evergreen.V686.Parser.Meta.Meta
