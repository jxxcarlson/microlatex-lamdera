module Evergreen.V650.Parser.Expr exposing (..)

import Evergreen.V650.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V650.Parser.Meta.Meta
    | Text String Evergreen.V650.Parser.Meta.Meta
    | Verbatim String String Evergreen.V650.Parser.Meta.Meta
