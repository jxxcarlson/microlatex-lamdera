module Evergreen.V157.Parser.Expr exposing (..)

import Evergreen.V157.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V157.Parser.Meta.Meta
    | Text String Evergreen.V157.Parser.Meta.Meta
    | Verbatim String String Evergreen.V157.Parser.Meta.Meta
