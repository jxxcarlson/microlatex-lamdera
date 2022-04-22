module Evergreen.V447.Compiler.DifferentialParser exposing (..)

import Evergreen.V447.Compiler.AbstractDifferentialParser
import Evergreen.V447.Compiler.Acc
import Evergreen.V447.Parser.Block
import Evergreen.V447.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V447.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V447.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V447.Parser.Block.ExpressionBlock) Evergreen.V447.Compiler.Acc.Accumulator
