Void = Nothing # 1.0 ripped Void for whatever reason

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

const cc = "C:\\Julia\\bin\\ChakraCore.dll"

#const ch = "C:\\repos\\ChakraCore\\Build\\VcBuild\\bin\\x64_release\\ch.dll"
#start_ch() = ccall( (:start_ch, ch), Void, ())
#start_ch()

const JsErrorCode = Int32
const JsRuntimeAttributeNone = Int32(0)

struct ChakraRuntime
	ref::Ref{Int64}
	function ChakraRuntime()
		this = new(Ref(0))
		ccall( (:JsCreateRuntime, cc), JsErrorCode, (Int32, Ptr{Int64}, Ptr{Int64}), 0, C_NULL, this.ref)
		return this
	end
end

struct ChakraContext
	ref::Ref{Int64}
	function ChakraContext(runtime::ChakraRuntime)
		this = new(Ref(0))
		ccall( (:JsCreateContext, cc), JsErrorCode, (Ptr{Int64}, Ptr{Int64}), deref(runtime.ref), this.ref)
		return this
	end
end

struct ChakraValue
	ref::Ref{Int64}
	function ChakraValue()
		return new(Ref(0))
	end
end

# JsPropertyId("test")
struct JsPropertyId
	ref::Ref{Int64}
	function JsPropertyId(str::AbstractString)
		this = new(Ref(0))
		errorCode = ccall( (:JsCreatePropertyId, cc), JsErrorCode, (Cstring, Csize_t, Ptr{Int64}), str, length(str), this.ref)
		return this
	end
end

function setCurrent(context::ChakraContext)::Bool
	value = ChakraValue()
	errorCode = ccall( (:JsSetCurrentContext, cc), JsErrorCode, (Ptr{Int64},), deref(context.ref))
end

function runScript(context::ChakraContext, code::AbstractString)::ChakraValue
	result = ChakraValue()
	errorCode = ccall( (:JsRunScript, cc), JsErrorCode, (Cwstring, Ptr{Int64}, Cwstring, Ptr{Int64}), code, deref(context.ref), "", result.ref)
	return result
end

function toString(value::ChakraValue)
	resultJSString = Ref(0)
	errorCode = ccall( (:JsConvertValueToString, cc), JsErrorCode, (Ptr{Int64}, Ptr{Int64}), deref(value.ref), resultJSString)
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
	object = ChakraValue()
	ccall( (:JsCreateObject, cc), JsErrorCode, (Ptr{Int64},), object.ref)
	return object
end

runtime = ChakraRuntime()
context = ChakraContext(runtime)
setCurrent(context)
result = runScript(context, "(()=>{return \'→asd\';})()")
resultString = toString(result)
print("resultString = $resultString\n")

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