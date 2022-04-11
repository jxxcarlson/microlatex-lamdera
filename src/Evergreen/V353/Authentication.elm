module Evergreen.V353.Authentication exposing (..)

import Dict
import Evergreen.V353.Credentials
import Evergreen.V353.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V353.User.User
    , credentials : Evergreen.V353.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
