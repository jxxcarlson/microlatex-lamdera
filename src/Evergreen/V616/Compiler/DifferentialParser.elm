module Evergreen.V616.Compiler.DifferentialParser exposing (..)

import Evergreen.V616.Compiler.AbstractDifferentialParser
import Evergreen.V616.Compiler.Acc
import Evergreen.V616.Parser.Block
import Evergreen.V616.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V616.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V616.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V616.Parser.Block.ExpressionBlock) Evergreen.V616.Compiler.Acc.Accumulator
