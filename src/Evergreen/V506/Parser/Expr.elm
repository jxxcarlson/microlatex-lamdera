module Evergreen.V506.Parser.Expr exposing (..)

import Evergreen.V506.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V506.Parser.Meta.Meta
    | Text String Evergreen.V506.Parser.Meta.Meta
    | Verbatim String String Evergreen.V506.Parser.Meta.Meta
