
# Index
- [Index](#index)
- [Examples](#examples)
  - [Cosine wave ring](#cosine-wave-ring)
  - [Radial waves (naive water shader)](#radial-waves)
  - [Health bars](#health-bars)
    - [Plain](#plain)
    - [From texture](#from-texture)
- [Shaders](#shaders)
  - [Case study](#case-study)
    - [Fresnel shader](#fresnel-shader)
    - [Return of the Obra Dinn](#return-of-the-obra-dinn)
    - [Other typical shaders](#other-typical-shaders)
  - [The structure of a shader (Unity)](#the-structure-of-a-shader-unity)
    - [.shader](#shader)
          - [**Properties**](#properties)
          - [**SubShader**](#subshader)
  - [A first look at shader code](#a-first-look-at-shader-code)
      - [Using variables](#using-variables)
      - [Why do we call "v2f" struct "Interpolators"?](#why-do-we-call-v2f-struct-interpolators)
      - [Swizzling](#swizzling)
      - [Why is the shade ""following" the transform of the object the material is applied to?](#why-is-the-shade-following-the-transform-of-the-object-the-material-is-applied-to)
- [Fragment shader](#fragment-shader)
  - ["Hello world"](#hello-world)
  - [Change color from material](#change-color-from-material)
  - [Patterns](#patterns)
    - [Normals](#normals)
      - [Using normals as colors](#using-normals-as-colors)
    - [UV coordinates & manipulation](#uv-coordinates--manipulation)
      - [Gradients](#gradients)
        - [Change the start and end of the gradient](#change-the-start-and-end-of-the-gradient)
      - [Triangle wave](#triangle-wave)
        - [Preprocessor constants](#preprocessor-constants)
      - [Cosine wave](#cosine-wave)
    - [Pattern manipulation](#pattern-manipulation)
  - [Animation](#animation)
    - [Ring](#ring)
  - [Blending mode](#blending-mode)
    - [Theory](#theory)
      - [Additive](#additive)
      - [Multiply](#multiply)
    - [Blending mode code](#blending-mode-code)
  - [Depth buffer & depth testing (ZTest)](#depth-buffer--depth-testing-ztest)
    - [Tinkering with the depth buffer](#tinkering-with-the-depth-buffer)
    - [Back to the ring shader](#back-to-the-ring-shader)
    - [Back face culling](#back-face-culling)
    - [Remove top and bottom](#remove-top-and-bottom)
    - [Give it colors!](#give-it-colors)
    - [Radial patterns](#radial-patterns)
- [Vertex shader](#vertex-shader)
  - [Foundations of a water shader](#foundations-of-a-water-shader)
  - [Ripples (radial waves)](#ripples-radial-waves)
- [Textures](#textures)

# Examples
## Cosine wave ring
![cosine-ring](https://user-images.githubusercontent.com/13524085/120125576-c8e70700-c18f-11eb-9021-eb1291c0665e.gif)

## Radial waves
![radial-waves](https://user-images.githubusercontent.com/13524085/120411912-041e3d00-c32c-11eb-91cb-557c7bc7bad6.gif)

## Health bars
### Plain
![healthbar](https://user-images.githubusercontent.com/13524085/120907199-fd4a3f80-c635-11eb-8868-8a24ac10aab2.gif)

### From texture
![healthbartexture](https://user-images.githubusercontent.com/13524085/120907200-00ddc680-c636-11eb-9a8f-02c95299c483.gif)

# Shaders
General idea: code that runs in the GPU and can adjust to certain inputs from geometry like normals, tangents, textures, uvs, etc.

## Case study
### Fresnel shader
As something starts to face away from you you get a stronger light, glowy. It's almost an outline effect. Classic "frozen" effect. When things make a steep angle with the camera, their color is stronger in the sense of lighter and more glowy; i.e., the surface is more reflective.

### Return of the Obra Dinn
Game has virtually two colors and then to express shading there's diddering.

### Other typical shaders
Water shaders with different types of blue according to depths and a foam rim. Plus reflections on that water (the mirror-like reflection on water is Fresnel in action). Fire shaders are also very typical.

## The structure of a shader (Unity)

### .shader
All of this except the proper HLSL code inside the "Pass" is part of Unity's own system for handling shaders, called ShaderLab, it's the boilerplate.

###### **Properties**
Colors, values, textures, mesh (matrix4x4, where it is, how it is rotated, how it is scaled, etc.). All of this is input for the shader code that's going to run.

**Shader vs material**: The mesh and the transformation Matrix4x4 are usually supplied by the **mesh renderer**. Colors, values and textures you have to define yourself, the usual way to define them is by using a **material**, which contains explicit values of each of these properties in addition to a **reference of the shader**. In Unity you can never apply a shader to an object, rather you apply a material to and object and that material then has a reference to the shader itself. So you can have different materials (different input data) that have a reference to the same shader (very common).

###### **SubShader**
You can have multiple subshaders for the same shader.
    
* **Pass**: proper code in HLSL is here.
    1. **Vertex shader**: takes all the vertices of your mesh. It's kind of a foreach loop of each vertex do something.In most cases what I want to do is put those vertices in some place in the world. But this shader doesn't want you to put things in *world space*, nor *local space*, nor *view space*, but it wants you to say where those vertex are going to be in **clip space**.
    
        Clip space is like a normalized space from `-1` to `1` inside of your render target or current view. The transformation is fairly simple taking the local space coordinates of each vertex and applying the MVP transformation matrix to convert it to clip space. So what the vertex shader does is:
        - Set the position of vertices.
        - Pass information to the fragment shader.

        It's normally used to animate water of trees swaying in the wind.
    2. **Fragment (pixel) shader**: is a foreach loop of every `Fragment` ("for each pixel inside the geometry that we are now rendering", between the vertex and the fragment shader there's GPU black magic) and basically set the color of each fragment (pixel that we are rendering).


## A first look at shader code
To create a shader, right-click in project, create, shader, and let's start with an "unlit shader". The starting point is this one:

```
Shader "Unlit/shader" {
    Properties {
        // Input data
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader {
        // Defines how the object should render,
        // sorting, if it is opaque, transparent,
        // change de queue. Render pipeline related.
        Tags { "RenderType"="Opaque" }
        
        // Use different subshaders according to the
        // LOD level
        LOD 100

        Pass {
            // Beginning of shader code.
            CGPROGRAM
            
            // Way to tell the compiler which function is
            // fragment shader and which one is the vertex
            // shader. We want the "vertex" shader to be
            // the one that's called "vert".
            #pragma vertex vert
            #pragma fragment frag

            // Include Unity lib to do some things more
            // efficiently, useful to include.
            #include "UnityCG.cginc"

            // Then you can define variables
            sampler2D _MainTex;
            float4 _MainTex_ST;

            // This is automatically filled up by Unity.
            struct appdata {
                // TERRIBLE NAME, usually renames it
                // to "MeshData".
                // This is the per-vertex mesh data

                // Vertex position in local space
                float4 vertex : POSITION;

                // UV coordinates. Often used for mapping textures
                // onto objects, but not necessarily. Also, can be
                // float4.
                float2 uv : TEXCOORD0;

                // Here "vertex" and "uv" are variables, we can
                // name them whatever we want. The ":" tells the
                // compiler that we want to store the POSITION and
                // TEXCOORD0, which refers to uv channel 0, which is,
                // usually the first one.

                // There are a limited number of things we can get
                // this way. Quite often: position, uv coordinates,
                // normals, color. Vertex normals are the way in which
                // vertices are pointing, usually used for shading.
                // Defined in local space.
                float3 normals : NORMAL;
                
                // Vertex color: (r, g, b, a)
                float4 color : COLOR;
                
                // Tangents, first three elements are the direction,
                // the forth is signed information.
                float4 tangent : TANGENT;
            };

            struct v2f {
                // The data that gets passed from the vertex shader
                // to the fragment shader. Usually renames it to
                // Interpolators.
                
                // Everything that we pass from the vertex shader to
                // the fragment shader has to exist insdie this structure.
                
                // Can be whatever we want it to be. In this case "TEXCOORD0"
                // does NOT refer to a uv channel. So if we want to pass
                // information, we can create a lot of this and pass
                // absolutely anything. The maximum is float4 though for
                // each interpolator.
                float2 uv : TEXCOORD0;

                // Clip space position
                float4 vertex : SV_POSITION;
            };


            // See that the signature for the vertex shader returns
            // a "v2f" struct, or "Interpolator"; and takes as input
            // the "MeshData" struct.
            v2f vert (appdata v) {
                // "o" for output.
                v2f o;
                
                // This function is multiplying by the MVP matrix
                // (model-view-projection matrix). It converts local
                // space to clip space. And then saves does to the
                // interpolator of vertex.
                o.vertex = UnityObjectToClipPos(v.vertex);
                return o;
            }

            // "float" (32 bit float), anything in world space mostly
            // or use float always.
            // "half" (16 bit float), very useful
            // "fixed" (lower precision ~12bit?), useful in the
            // -1 to 1 range.
            // Where there's a fixed4 -> half4 -> float4, so if you wanna
            // make a matrix: fixed4x4 -> half4x4 -> float4x4 (C#: Matrix4x4)

            // See the signature, takes in an "v2f" or "Interpolator".
            // The semantic ": SV_Target" is telling the compiler that this
            // fragment shader should output to the frame buffer.
            fixed4 frag (v2f i) : SV_Target {
                return float4(1, 0, 0, 1);  // returns red. "Hello world".
            }
            ENDCG
        }
    }
}
```

#### Using variables
Let's say we want to display some variable in the UI and use it in our shader code.

```
Shader "Unlit/shader" {
    Properties {
        // Input data
        _Value ("Value", Float) = 1.0
    }
    SubShader {
        Pass {
            CGPROGRAM
            float _Value;
            ENDCG
        }
    }
}
```
Then if we create **materials** we can specify different values for each material that uses the shader.

#### Why do we call "v2f" struct "Interpolators"?
Vertices have information, everything in between does not. The vertex shader has a per-vertex foreach loop, and then, the fragment shader a per-pixel one. But what information do these pixels hold? How does it look like? For example the normal information for that pixel, how is it defined? Well, it's an interpolation between the two vertices, a blend between the normals defined for each vertex. And this goes for any data, suppose vertex 1 has a red color and vertex 2 is blue; then the pixel in between will be the interpolation (LERP) of these two colors. In a triangle, to get technical, when you blend between 3 points, it's called **Barry-centric interpolation**. So everything inside a triangle gets blended/interpolated and that's the information that receives the fragment shader.

That's why they're called interpolators, because every data that you set in the vertex shader, that's gonna be passed to the fragment shader, is gonna be interpolated in exactly this way, whatever data that might be. So, in the fragment shader, you only have access to the interpolated data for any given fragment that you are rendering. And of course it's not gonna be a single pixel, but a bunch of them.

#### Swizzling
Imagine that in your fragment shader you have a color:

```
float4 frag(Interpolators i) : SV_Target {
    float4 myValue;
    
    // Then you can
    float2 otherValue = myValue.rg;  // (red, green)
    float2 otherValueFlipped = myValue.gr  // (green, red)
    float2 withOtherAccesors = myValue.xy
    float4 spreadFirstVal = myValue.xxxx
}
```

#### Why is the shade ""following" the transform of the object the material is applied to?
It seems trivial, but it's not, this is because we're telling the shader to convert local space to clip space in the vertex shader:

```
Interpolators vert (MeshData v) {
    Interpolators o;
    o.vertex = UnityObjectToClipPos(v.vertex);
    return o;
}
```
This is not always the case. If we just set to `o.vertex = v.vertex` is going to stuck in the camera, rendering it directly into clip space. This would be useful to create **post processing shaders**, since we usually want to cover the entire screen.


# Fragment shader

## "Hello world"
Let's make a shader that all it does it position vertices at some position in the world, in this case corresponding to a transform attached to a sphere; this will be handled by the vertex shader. Then, paint everything a hardcoded color in the fragment shader.

```
CGPROGRAM
#pragma vertex vert
#pragma fragment frag

#include "UnityCG.cginc"

struct MeshData
{
    float4 vertex : POSITION;
    float2 uv0 : TEXCOORD0;
    float3 normals : NORMAL;
};

struct Interpolators
{
    // float2 uv : TEXCOORD0;
    float4 vertex : SV_POSITION;
};

Interpolators vert (MeshData v)
{
    Interpolators o;
    o.vertex = UnityObjectToClipPos(v.vertex);
    return o;
}

float4 frag(Interpolators i) : SV_Target
{
    return float4(1, 0, 0, 1);  // red
}
ENDCG
```

## Change color from material
Let's say we want to change the color that's being outputted by the fragment shader, and have different materials for different colors; then we can:

```
Shader "Unlit/Shader1"
{
    Properties
    {
        _MyColor("Some Color", Color) = (1,1,1,1)
    }
        SubShader
    {
        Tags { "RenderType" = "Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            float4 _MyColor;

            struct MeshData
            {
                float4 vertex : POSITION;
                float2 uv0 : TEXCOORD0;
                float3 normals : NORMAL;
            };

            struct Interpolators
            {
                // float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            Interpolators vert (MeshData v)
            {
                Interpolators o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                return o;
            }

            float4 frag(Interpolators i) : SV_Target
            {
                return _MyColor;
            }
            ENDCG
        }
    }
}
```

Notice how `Color` type in Unity is being mapped to `float4`.

## Patterns
### Normals
In order to pass something from the vertex shader to the fragment shader, we need to pass that in the interpolator structure. We need to have a `float3` and then the semantic for that can be `TEXCOORD0`, it doesn't matter, that doesn't correspond to uv coordinates in this scope; just to one of the data streams that we have coming from the vertex shader to the fragment shader.

```
struct Interpolators {
    float4 vertex : SV_POSITION;
    float3 normal : TEXCOORD0;
}
```

#### Using normals as colors
We can have an rgb sphere just passing the normals as data input to the fragment shader, and using the normals as colors.

```
float4 _MyColor;

struct MeshData
{
    float4 vertex : POSITION;
    float2 uv0 : TEXCOORD0;
    float3 normals : NORMAL;
};

struct Interpolators
{
    // float2 uv : TEXCOORD0;
    float4 vertex : SV_POSITION;
    float3 normal : TEXCOORD0;
};

Interpolators vert (MeshData v)
{
    Interpolators o;
    o.vertex = UnityObjectToClipPos(v.vertex);
    o.normal = v.normals;  // just pass data through
    return o;
}

float4 frag(Interpolators i) : SV_Target
{
    return float4( i.normal, 1 );  // notice the swizzling
}
ENDCG
```
This shader will display the direction of the normal for every given pixel that we are rendering. It's outputting the vectors as color, since shader make no distinctions between those two.

If we rotate this sphere we are going to see that those directions are relative to local space and the outputted colors, thus, will rotate with the object; but we might want them to be relative to world space:

```
Interpolators vert (MeshData v)
{
    Interpolators o;
    o.vertex = UnityObjectToClipPos(v.vertex);
    
    // Just a matrix multiplication, manully it would be:
    // o.normal = mul((float3x3)unity_ObjectToWorld, v.normals);

    // Or we could also use the "M" matrix from the MVP:
    // o.normal = mul((float3x3)UNITY_MATRIX_M, v.normals);
    o.normal = UnityObjectToWorldNormal(v.normals);

    return o;
}
```

We could do this math in the fragment shader, it works exactly the same way. But this is where you have a very simple optimization: try to think how many vertices you have vs how many fragments (or pixels). In most cases you have more pixels than vertices, so you usually want all possible math in the vertex shader instead of the fragment shader.

If there's a really complex mesh, with a lot of vertices, but rendered very far away, so that it takes up a few pixels, then in this case it might be better to do the math in the fragment shader, but it's a border case.

### UV coordinates & manipulation
Usually UV coordinates are 2D coordinates, they specify a 2D coordinate on your mesh. These coordinates depend on how the object was UV mapped when the artist created it. If we were to:

```
float4 frag (Interpolators i) : SV_Target {
    return float4 (i.uv.xxx, 1);
}
```
We would see a horizontal gradient of black and white. , while `i.uv.yyy` would be vertical. With `i.uv, 0, 1` we would have red and green being added together, red growing in the x-axis and green in the y-axis.

Imagine our fragment shader just visualizes our UVs:

```
float4 frag(Interpolators i) : SV_Target {
    return float4( i.uv, 0, 1 );
}
```

Let's say we want to scale and to offset UV coordinates, we could do something like:
`o.uv = (v.uv0 + _Offset) * _Scale;` in the vertex shader, where `_Offset` and `_Scale` are `Float` properties. What this will do is change were the colors are imprinted in the shape. Scaling them by a positive factor, for instance, would mean that they reach a yellow-ish color more quickly, while offsetting them would change the `(0, 0)` of the gradient.

#### Gradients
Let's say we want to blend between two colors and obtain a gradient horizontally. To LERP, remember also that we need a value that goes from 0 to 1. Now, suppose that our vertex shader passes through the uv's untouched, then we have a value from 0 to 1 horizontally across our mesh: `float4(i.uv.xxx, 1)`, so we can use it as the `t` parameter to LERP between two colors:

```
float4 frag(Interpolators i) : SV_Target {
    // Blend between two colors based on the X UV coordinate
    float4 outColor = lerp(_ColorA, _ColorB, i.uv.x);
    return outColor;
}
```

##### Change the start and end of the gradient
We can define the following properties:

```
Properties {
    _ColorA("ColorA", Color) = (1,1,1,1)
    _ColorB("ColorB", Color) = (1,1,1,1)
    _ColorStart("Color Start", Float) = 0
    _ColorEnd("Color End", Float) = 1
}
```
And then have something like:

```
float InverseLerp(float a, float b, float v) {
    return (v - a) / (b - a);
}
float4 frag(Interpolators i) : SV_Target {
    float t = InverseLerp(_ColorStart, _ColorEnd, i.uv.x);
    float4 outColor = lerp(_ColorA, _ColorB, t);
    return outColor;
}
```
But this impelementation has a problem, we are not checking if `t` is between `[0, 1]`. If we just `return t` in the fragment shader we are going to see black and white and nothing will tell us that we are overshading.

* **frac(v)** function is the same as doing: `v - floor(v)`, so it will clamp `t` to a 01 range, but it will give us a repeating pattern.
* **saturate(v)** is `Mathf.Clamp01` in HLSL but with a horrible name.

So we can do the following:

```
float InverseLerp(float a, float b, float v) {
    return (v - a) / (b - a);
}

float4 frag(Interpolators i) : SV_Target {
    float t = saturate(InverseLerp(_ColorStart, _ColorEnd, i.uv.x));
    float4 outColor = lerp(_ColorA, _ColorB, t);
    return outColor;
}
```

Instead of lerp, we could use a **smooth step** which is three things, an inverse lerp, a clamp and a cubic function. It's not a lerp but a cubic smooth.

#### Triangle wave
A triangular wave or triangle wave is a non-sinusoidal waveform named for its triangular shape. So let's say we have a quad, and we want it to be striped. We could devise a function which's graphic resembles a triangular shape in the first quadrant of R2, between 0 and 1. We can do something like `|(x * 2) - 1|` to get a `V` shape. But what happens when x is bigger than 1? In our shader, we can use `frac` to create a pattern.

Let's look at what would happen if we do

```
float4 frag(Interpolators i) : SV_Target {
    return frac(i.uv.x * 5);
}
```
We would get 5 repeating patterns from 0 to 1: [[0..1], [0..1], [0..1], [0..1], [0..1]]; so the final pattern would be from black to white and then an abrupt fall to black again. Now let's do a triangle wave:

```
float4 frag(Interpolators i) : SV_Target {
    return abs(frac(i.uv.x * 5) * 2 - 1);
}
```
We would have 5 stripes that go from 1 to 0 in the middle, and then to 1 again; so there'll be no abrupt falls between series.

Basically, this idea can be repeated for any behaviour given a function defined for x between 0 and 1 taking a look at the image between 0 and 1 for all x's in that range (we can have a square wave pattern, a sawtooth, etc.).

We can also use trigonometric waves, like `cos` or `sin`, etc.

##### Preprocessor constants
You can define things as name for stuff, macros, etc. which will be directed replaced by the value when compiled. A typical define:

```
#define TAU 6.28318530718
```
Because for trigonometric functions, something like `cos(i.uv.x * TAU * 2)` is guaranteed to be a full period.

#### Cosine wave
Let's do a cosine wave, but instead of going along the x-axis, we want to traverse both of them, getting a checked pattern.

```
float4 frag(Interpolators i) : SV_Target {
    float2 t = cos(i.uv.xy * TAU * _Repeat) * 0.5 + 0.5;
    return float4(t, 0, 1);
}
```
Where `_Repeat` is user defined and refers to an integer which specified how many "squares" per row/col are in the checked pattern.

### Pattern manipulation

 What if we want a diagonal pattern? Or a wiggly-like one? We can modify the outputted color of the fragment shader in terms of how high it's in the `y` coordinate of the uv map, or how far in the `x` row it is, a diagonal would be a **linear function** between `x` and `y`. So:
 
```
float4 frag(Interpolators i) : SV_Target{
    float xOffset = i.uv.y;

    float t = cos((i.uv.xy + xOffset) * TAU * _Repeat) * 0.5 + 0.5;

    float4 outColor = lerp(_ColorA, _ColorB, t);
    return outColor;
}
```

To make a **wiggly-pattern**, we can think again in trigonometry and the cosine function:

```
float4 frag(Interpolators i) : SV_Target{
    float xOffset = cos(i.uv.y * TAU * 2) * 0.1;

    float t = cos((i.uv.xy + xOffset) * TAU * _Repeat) * 0.5 + 0.5;

    float4 outColor = lerp(_ColorA, _ColorB, t);
    return t;
}
```

We multiply it by `TAU` so each "column" is a full period, but it will be outside of the frame (in a quad for example), so we can scale it with `0.1` to reduce the "wiggly-ness". But then perhaps we want two wiggles instead of one, so we multiply by `2`, thus, reducind the period by a half.

## Animation
It's very easy to animate a pattern for example, there's a `_Time` variable supplied by Unity that we can use in shaders, it has xyzw components which use different scales of time. `y` is seconds, `w` is seconds divided by 20.

We can animate the above wiggly pattern like this:

```
float4 frag(Interpolators i) : SV_Target{
    float xOffset = cos(i.uv.y * TAU * 2) * 0.1;

    float t = cos((i.uv.x + xOffset + _Time.y * 0.1) * TAU * _Repeat) * 0.5 + 0.5;

    float4 outColor = lerp(_ColorA, _ColorB, t);
    return t;
}
```

The `_Time.y * 0.1` is to slow it down.

### Ring
Let's say we want a ring around an object. We can animate a cylinder in a similar fashion as earlier, but this time we want the animation to be in the y-axis, so we switch the variables and we substract the time insead of adding it, that way we make it go in the other direction:

```
float4 frag(Interpolators i) : SV_Target{
    float xOffset = cos(i.uv.x * TAU * 2) * 0.1;

    float t = cos((i.uv.y + xOffset - _Time.y * 0.1) * TAU * _Repeat) * 0.5 + 0.5;

    float4 outColor = lerp(_ColorA, _ColorB, t);
    return t;
}
```

Now, we want the ring to "fade" as we go up, we need to come up with a value that ranges from 1 to 0 as we go up. If we output `i.uv.y` we can see that it's the exact value we need. An easy way to fade something to black is to multiply, remember that a multiply blending mode gives us a darker color.

```
float4 frag(Interpolators i) : SV_Target{

    float xOffset = cos(i.uv.x * TAU * 5) * 0.01;

    float t = cos((i.uv.y + xOffset - _Time.y * 0.2) * TAU * _Repeat) * 0.5 + 0.5;
    t *= 1 - i.uv.y;  // fade as we go up
    return t;
}
```

## Blending mode
Cómo un efecto se combina con el fondo. 

* **additive**: hace más claro al fondo, como un glow effect.
* **multiply**: lo hace más oscuro al fondo.
* **regular**: alpha blending, or alpha composing, que es cuando renderizás una cosa encima de otra, opaco, o no modifican mucho el fondo. You blend towards the color that you have defined.

Until now, we are rendering fully opaque colors, there's no way of dealing with transparency.

### Theory
The color that we get from the fragment shader is usually called the "source" color (in terms of blending), shortened as `src`; then we have the background, as in the destination we are blending to, what's already behing the object, shortened as `dst`.

So, in the most basic form, the way that it works is asa follow:

> `src * a +/- dst * b`

So if we wanna change the mathematical formula that determines how something is going to blend with the background, we can modify: `a`, `b`, or the `+/-`. That's what we have to work with to achieve the desired effect that we want.

#### Additive
With the theory in mind, let's say we want to do additive blending, which kind of just adds light. Really useful for flashy effects, like fire, etc. In order to do this, all we need to do is:

* `a = 1`
* `b = 1`
* And choose `+`

#### Multiply
We want to have `src * dst`. This will get us a darker color. With the parameters that we can tinker with, we just:

* `a = dst`
* `b = 0`

### Blending mode code
Blending modes are defined in the `Pass`, but they're not actually shader code but shader lab, so Unity specific (outside the HLSL code). It's just one line that defines the blending mode.

```
Pass {
    Blend One One  // Additive
    Blend DstColor Zero // Multiply
    
    CPROGRAM
    ...
}
```

## Depth buffer & depth testing (ZTest)
As soon as we get into things that are transparent, we can into the issues of the depth buffer, or whether or not we should write into the depth buffer.

If we add `Blend One One` (additive blending) to our prior ring shader, and start playing with a sphere, we will see that it kind of works but it has some sorting issues (sometimes the shader completely opaques the sphere).

The depth buffer is kind of a big screen texture where some shaders write a depth value which is between 0 and 1. And when other shader want to render, they check this depth buffer to see if "is this fragment in front or behind the depth buffer", and if it is behind, it will not render.

So we have the camera, and we are writing to the depth buffer with some object. So what this means is that it will basically make the depth buffer to go from the far clip of the camera , to the object which is going to have values very close to the camera because we wrote the depth buffer, and back to the far clip, creating a "cone" behind which nothing is rendered, because we already have something in front of it. So, **we can't do this if we want the object to be transparent; we can't write that object in the depth buffer.** This method works for opaque objects.

### Tinkering with the depth buffer
Basically two ways:

1. Change the way it reads from the depth buffer.

    If we move the sphere across the ring, we will see that (supposing `ZWrite Off`) the pixels of the ring that are opaqued by the sphere are not rendering. That's because we are still reading from the depth buffer, but perhaps we don't want that. For that, we have `ZTest` for how the testing should work out when presented with a depth buffer with some value.
    
    The default value is called `ZTest LEqual` which means that "if the depth of this objects is less than or equal to the depth already written into the depth buffer, show it, otherwise don't".
    
    If we want it to always draw, we can set it to `Always`, so now even if the ring is behind the sphere it's still going to draw.
    
    We can also set it to `GEqual`, so it's going to draw if it is behind something, and not going to draw if it is in font.

2. Change the way it write to the depth buffer: `ZWrite Off`

### Back to the ring shader
So if we `ZWrite Off`, we stop the funky-ness with the z-sorting. But now we have an additional problem, the ring shader is being rendered before the sphere; so the sphere is writing to the depth buffer and just overriting everything we are drawing here.

In **Unity's default rendering pipeline**, basically there's an order in which different types of geometry tends to render.

1. **Skybox** is the first thing that it renders.
2. **Opaque** or **geometry**.
3. **Transparent** which usually groups all additive, multiplicative and other transparents.
4. Then you have **overlays** like flaers, etc., that tend to go above everything else.

So when we are dealing with transparent things, we want to define some tags in the shader:

```
Tags {
    "RenderType" = "Transparent"
    "Queue" = "Transparent"
}
```

`Queue` is the one that changes the render order. We want to render all our transparent objects after the **opaque** has rendered, so we need to change it from **Opaque** to **Transparent**, which, as seen earlier, renders afterwards in the pipeline. `RenderType` is mostly for tagging purposes for post processing, it informs the render pipeline what type this is, it doesn't change the sorting.

### Back face culling
What if we want the ring to be double-sided? We can't see the other side of the ring, albeit it being transparent; when we can't see the other face, the effect is known as **back face culling** and defined as `Cull Back`, which is the default value.

We could set it to `Front`, and it's going to flip; it's not going to render the front side of the triangles, only the back side.

If we want to render both, we say `Cull Off`, so, render both sides of the triangles.

### Remove top and bottom
We can hack them away:

```
float4 frag(Interpolators i) : SV_Target{

    float xOffset = cos(i.uv.x * TAU * 5) * 0.01;

    float t = cos((i.uv.y + xOffset - _Time.y * 0.2) * TAU * _Repeat) * 0.5 + 0.5;
    t *= 1 - i.uv.y;
    return t * (abs(i.normal.y) < 0.999);
}
```
We are returning 0 when the direction of the normal points almost entirely up or down.

### Give it colors!
We can seamlessly reintegrate the colors:

```
float4 frag(Interpolators i) : SV_Target{

    float xOffset = cos(i.uv.x * TAU * 8) * 0.01;

    float t = cos((i.uv.y + xOffset - _Time.y * 0.2) * TAU * _Repeat) * 0.5 + 0.5;
    t *= 1 - i.uv.y;

    float topBottomRemover = abs(i.normal.y) < 0.999;
    float waves = t * topBottomRemover;

    float4 gradient = lerp(_ColorA, _ColorB, i.uv.y);
    return gradient * waves;
}
```
As `_ColorB` we should have black since additive with black is the same as nothing, which gives us a fade effect.

### Radial patterns
Until now we've been doing linear patterns, for a radial pattern we can use the distance from the center while transforming the (0, 0) of the uvs.

```
float4 frag(Interpolators i) : SV_Target{
    float2 uvsCentered = i.uv * 2 - 1;
    float radialDistance = length(uvsCentered);

    return float4(radialDistance.xxx, 1);
}
```

And if we incorporate the waves to it, we would have a trippy effect.

```
float4 frag(Interpolators i) : SV_Target{
    float2 uvsCentered = i.uv * 2 - 1;
    float radialDistance = length(uvsCentered);

    float wave = cos((radialDistance - _Time.y * 0.1) * TAU * _Repeat) * 0.5 + 0.5;
    return wave;
}
```

And perhaps make it fade-out towards the edges adding: `wave *= 1 - radialDistance;`.


# Vertex shader
The achieved effect would greatly depend on the geomtry used. For example a standard Unity plane won't reflect the intuitions for the following shaders; a **tessellated plane** (with a LOT of geometry, i.e., vertices) will.

## Foundations of a water shader

We can take the cosine function with our color waves from the fragment shader and use it to offset the y position of the vertices in the vertex shader.

```
Interpolators vert(MeshData v) {
    Interpolators o;

    float wave = cos((v.uv0.y - _Time.y * 0.1) * TAU * _Repeat);

    v.vertex.y = wave * _WaveAmp;
    o.vertex = UnityObjectToClipPos(v.vertex);
    o.normal = UnityObjectToWorldNormal(v.normals);  // matrix multiplication
    o.uv = v.uv0;

    return o;
}
```

We created a variable `_WaveAmp` to control the wave amplitude.

## Ripples (radial waves)
We can extract the wave calculation from the prior fragment shader and use it to calculate the displacement of the y-axis for each vertex.

```
float GetWave(float2 uv) {
    float2 uvsCentered = uv * 2 - 1;
    float radialDistance = length(uvsCentered);

    float wave = cos((radialDistance - _Time.y * 0.1) * TAU * _Repeat) * 0.5 + 0.5;
    wave *= 1 - radialDistance;
    return wave;
}

Interpolators vert(MeshData v) {
    Interpolators o;

    float waveY = cos((v.uv0.y - _Time.y * 0.1) * TAU * _Repeat);
    float waveX = cos((v.uv0.x - _Time.y * 0.1) * TAU * _Repeat);

    v.vertex.y = GetWave(v.uv0) * _WaveAmp;  // Important line

    o.vertex = UnityObjectToClipPos(v.vertex);
    o.normal = UnityObjectToWorldNormal(v.normals);  // matrix multiplication
    o.uv = v.uv0;

    return o;
}
```

# Textures
