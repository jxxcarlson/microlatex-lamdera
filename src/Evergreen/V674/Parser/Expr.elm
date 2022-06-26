module Evergreen.V674.Parser.Expr exposing (..)

import Evergreen.V674.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V674.Parser.Meta.Meta
    | Text String Evergreen.V674.Parser.Meta.Meta
    | Verbatim String String Evergreen.V674.Parser.Meta.Meta
