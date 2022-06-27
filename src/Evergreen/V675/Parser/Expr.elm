module Evergreen.V675.Parser.Expr exposing (..)

import Evergreen.V675.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V675.Parser.Meta.Meta
    | Text String Evergreen.V675.Parser.Meta.Meta
    | Verbatim String String Evergreen.V675.Parser.Meta.Meta
