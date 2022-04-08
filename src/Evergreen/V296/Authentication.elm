module Evergreen.V296.Authentication exposing (..)

import Dict
import Evergreen.V296.Credentials
import Evergreen.V296.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V296.User.User
    , credentials : Evergreen.V296.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
