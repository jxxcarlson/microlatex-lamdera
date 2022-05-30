module Evergreen.V533.Parser.Expr exposing (..)

import Evergreen.V533.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V533.Parser.Meta.Meta
    | Text String Evergreen.V533.Parser.Meta.Meta
    | Verbatim String String Evergreen.V533.Parser.Meta.Meta
