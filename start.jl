if !isdefined(:Void)
	Void = Nothing # 1.0 ripped Void for whatever reason
end

# https://stackoverflow.com/questions/51994365/convert-refcwstring-to-string/51998210
function Base.unsafe_string(w::Cwstring)
	ptr = convert(Ptr{Cwchar_t}, w)
	ptr == C_NULL && throw(ArgumentError("cannot convert NULL to string"))
	buf = Cwchar_t[]
	i = 1
	while true
		c = unsafe_load(ptr, i)
		if c == 0
			break
		end
		push!(buf, c)
		i += 1
	end
	return String(transcode(UInt8, buf))
end

Base.pointer(ref::Ref) = Base.unsafe_convert(Ptr{eltype(ref)}, ref)
# deref is pretty much ref.x, but converting to Ptr{} here aswell
deref(ref::Ref) = Ptr{Int64}( ref.x )

#const cc = "C:\\Julia\\bin\\ChakraCore.dll"
const cc = "C:\\Users\\kung\\AppData\\Local\\Julia-0.6.2\\bin\\ChakraCore.dll"

#const ch = "C:\\repos\\ChakraCore\\Build\\VcBuild\\bin\\x64_release\\ch.dll"
#start_ch() = ccall( (:start_ch, ch), Void, ())
#start_ch()

const JsErrorCode = Int32
const JsRuntimeAttributeNone = Int32(0)

struct ChakraRuntime
	ptr::Ptr{Int64}
	function ChakraRuntime()
		tmp = Ref{Int64}(0)
		ccall( (:JsCreateRuntime, cc), JsErrorCode, (Int32, Ptr{Int64}, Ptr{Int64}), 0, C_NULL, tmp)
		return new(tmp.x)
	end
end

struct ChakraContext
	ptr::Ptr{Int64}
	function ChakraContext(runtime::ChakraRuntime)
		tmp = Ref{Int64}(0)
		ccall( (:JsCreateContext, cc), JsErrorCode, (Ptr{Int64}, Ptr{Int64}), runtime.ptr, tmp)
		return new(tmp.x)
	end
end

struct ChakraValue
	ptr::Ptr{Int64}
end

# JsPropertyId("test")
struct JsPropertyId
	ptr::Ptr{Int64}
	function JsPropertyId(str::AbstractString)
		tmp = Ref{Int64}(0)
		errorCode = ccall( (:JsCreatePropertyId, cc), JsErrorCode, (Cstring, Csize_t, Ptr{Int64}), str, length(str), tmp)
		return new(tmp.x)
	end
end

function setCurrent(context::ChakraContext)::Bool
	errorCode = ccall( (:JsSetCurrentContext, cc), JsErrorCode, (Ptr{Int64},), context.ptr)
end

function runScript(context::ChakraContext, code::AbstractString)::ChakraValue
	tmp = Ref{Int64}(0)
	errorCode = ccall( (:JsRunScript, cc), JsErrorCode, (Cwstring, Ptr{Int64}, Cwstring, Ptr{Int64}), code, context.ptr, "", tmp)
	return ChakraValue(tmp.x)
end

function toString(value::ChakraValue)
	resultJSString = Ref(0)
	#println("value.ptr = ", value.ptr)
	errorCode = ccall( (:JsConvertValueToString, cc), JsErrorCode, (Ptr{Int64}, Ptr{Int64}), value.ptr, resultJSString)
	#println("resultJSString = $resultJSString")
	#print("errorCode = $errorCode\n")
	#print("resultJSString = $resultJSString\n")
	resultWC = Ref{Cwstring}()
	stringLength = Ref{Csize_t}(0)
	errorCode = ccall( (:JsStringToPointer, cc), JsErrorCode, (Ptr{Int64}, Ptr{Int64}, Ptr{Csize_t}), deref(resultJSString), pointer(resultWC), stringLength)
	resultString = Base.unsafe_string(resultWC.x)
	return resultString
end

# julia> toString(JsCreateObject())
# "[object Object]"
function JsCreateObject()
	tmp = Ref{Int64}(0)
	ccall( (:JsCreateObject, cc), JsErrorCode, (Ptr{Int64},), tmp)
	return ChakraValue(tmp.x)
end

# julia> toString(JsGetGlobalObject())
# "[object global]"
function JsGetGlobalObject()
	tmp = Ref{Int64}(0)
	ccall( (:JsGetGlobalObject, cc), JsErrorCode, (Ptr{Int64},), tmp)
	return ChakraValue(tmp.x)
end

# julia> toString(JsCreateString("no unicode support"))
# "no unicode support"
function JsCreateString(str::AbstractString)
	tmp = Ref{Int64}(0)
	ccall( (:JsCreateString, cc), JsErrorCode, (Cstring, Csize_t, Ptr{Int64}), str, length(str), tmp)
	return ChakraValue(tmp.x)
end



# 
#function JsCreateNamedFunction(str::AbstractString)
#	val = ChakraValue()
# JsCreateNamedFunction(nameVar, callback, nullptr, functionVar)
#	ccall( (:JsCreateNamedFunction, cc), JsErrorCode, (Cstring, Csize_t, Ptr{Int64}), str, length(str), val.ref)
#	return val
#end

runtime = ChakraRuntime()
context = ChakraContext(runtime)
setCurrent(context)
result = runScript(context, "(()=>{return \'→asd\';})()")
resultString = toString(result)
print("resultString = $resultString\n")

function someFunc(callee::ChakraValue, isConstructCall::Bool, arguments::Vector{ChakraValue}, callbackState::ChakraValue)::ChakraValue
	for arg in arguments
		println( toString(arg) )
	end
	return JsCreateString("yo")
end

# julia> toString(runScript(context, "somefunc.bind(444)('one','two')"))
# argumentCount=3
# 444
# one
# two
# "yo"


#function wrapper_callback_test(targ::Ptr{Int64}, inflictor::Ptr{Int64}, attacker::Ptr{Int64}, dir::Ptr{Float32}, point::Ptr{Float32}, damage::Int32, dflags::Int32, mod::Int32, )::Int32
#	ret = zero(Int32)
#	# whatever happens, make sure we return to C what it expects
#	try
#		# for some reason cfunction returns always the first compiled one, so make sure we call the latest function here
#		ret = Int32( Base.invokelatest(callback_player_damage, convert(Entity, targ), convert(Entity, inflictor), convert(Entity, attacker), convert(Vec3, dir), convert(Vec3, point), damage, dflags, mod) )
#	catch ex
#		log(console, ex)
#	end
#	return ret
#end
 
#get_module(obj) = typeof(obj).name.module
#ptr = pointer_from_objref(Symbol("eye"))
#ccall( :jl_get_global, Ptr{Int64}, (Ptr{Int64}, Ptr{Int64}), pointer_from_objref(Base), ptr)
#STATIC_INLINE jl_function_t *jl_get_function(jl_module_t *m, const char *name) {
#    return (jl_function_t*)jl_get_global(m, jl_symbol(name));
#}
# Base.unsafe_pointer_to_objref(ptr)

dont_garbagecollect_these_functions = []

function native_wrapper_for_func(callee::Ptr{Int64}, isConstructCall::Bool, arguments::Ptr{Int64}, argumentCount::UInt16, callbackState::Ptr{Int64})::Ptr{Int64}
	#log(console, "player_damage $targ $inflictor $attacker $dir $point $damage $dflags $mod")
	#zero(Int32)
	println("argumentCount=$argumentCount")
	println("callbackState=$callbackState")
	args = ChakraValue[]
	# someFunc(1,2,3) will have argumentCount==4, 0==this
	for i in 0:argumentCount-1
		push!(args, ChakraValue( unsafe_load(arguments + sizeof(Int64) * i)) )
	end
	restoredFunc = Base.unsafe_pointer_to_objref(callbackState)
	ret = restoredFunc(
		ChakraValue(callee),
		isConstructCall,
		args,
		ChakraValue(callbackState)
	)
	return ret.ptr
end

function JsCreateNamedFunction(func)::ChakraValue
	global dont_garbagecollect_these_functions
	push!(dont_garbagecollect_these_functions, func)
	c_callback_text = cfunction(native_wrapper_for_func, Ptr{Int64}, (Ptr{Int64}, Bool, Ptr{Int64}, UInt16, Ptr{Int64}))
	str_testfunc = JsCreateString( string(func) ) # e.g. string(eye) == "eye"
	tmp = Ref{Int64}(0)
	ccall( (:JsCreateNamedFunction, cc), JsErrorCode, (Ptr{Int64}, Ptr{Int64}, Ptr{Int64}, Ptr{Int64}), str_testfunc.ptr, c_callback_text, Ptr{Int64}(pointer_from_objref(func)), tmp)
	func = ChakraValue(tmp.x)
	return func
end

# JsSetProperty(JsValueRef object, JsPropertyIdRef property, JsValueRef value, bool useStrictRules)

function JsSetProperty(object, property, value, useStrictRules)::JsErrorCode
	ccall( (:JsSetProperty, cc), JsErrorCode, (Ptr{Int64}, Ptr{Int64}, Ptr{Int64}, Bool), object, property, value, useStrictRules)
end

func = JsCreateNamedFunction(someFunc)

JsSetProperty(
	JsGetGlobalObject().ptr,
	JsPropertyId("somefunc").ptr,
	func.ptr,
	true
)

# julia> runScript(context, "somefunc()")
# straight outta callback_test

print("func=$func\n")

#ccall(("set_callback_player_damage", lib), Void, (Ptr{Int64}, ), c_callback_player_damage)


#=
jsref = Ptr{Int64}(0)
JsCreateObject() = ccall( (:JsCreateObject, cc), Int32, (Ptr{Int64},), jsref)
IfJsrtErrorSetGo(ChakraRTInterface::JsCreateContext(runtime, &newContext));
ccall( (:JsGetCurrentContext, cc), Void, (Ptr{Int64},), jsref)
# IfJsErrorFailLog(ChakraRTInterface::JsCreateRuntime(jsrtAttributes, nullptr, runtime));
#  65539 = JsErrorNoCurrentContext
#  65538 = JsErrorNullArgument
# 196610 = JsErrorScriptCompile
=#