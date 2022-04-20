module Evergreen.V430.Authentication exposing (..)

import Dict
import Evergreen.V430.Credentials
import Evergreen.V430.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V430.User.User
    , credentials : Evergreen.V430.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
