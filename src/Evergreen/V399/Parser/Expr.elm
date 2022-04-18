module Evergreen.V399.Parser.Expr exposing (..)

import Evergreen.V399.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V399.Parser.Meta.Meta
    | Text String Evergreen.V399.Parser.Meta.Meta
    | Verbatim String String Evergreen.V399.Parser.Meta.Meta
