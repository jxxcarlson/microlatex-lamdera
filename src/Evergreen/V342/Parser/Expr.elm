module Evergreen.V342.Parser.Expr exposing (..)

import Evergreen.V342.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V342.Parser.Meta.Meta
    | Text String Evergreen.V342.Parser.Meta.Meta
    | Verbatim String String Evergreen.V342.Parser.Meta.Meta
