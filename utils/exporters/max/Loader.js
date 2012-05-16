(function() {

    Loader = function(showStatus) {
        THREE.JSONLoader.call( this, showStatus );
    }
    
    Loader.prototype = new THREE.JSONLoader();
    Loader.prototype.constructor = Loader;
    Loader.prototype.supr = THREE.JSONLoader.prototype;
    
    var IMPORT_MORPHNORMALS = true
    
    Loader.prototype.createModel = function ( json, callback, texturePath ) {
        var Callback = function(geometry) {
            
            geometry.maxObjectName = json.metadata.name
            
            if ( json.morphTargets !== undefined ) {
            
                for(var i in json.morphTargets ) {
                    geometry.morphTargets[ i ].action = json.morphTargets[ i ].action; // pks: Animation Name
                    geometry.morphTargets[ i ].frame = json.morphTargets[ i ].keyframe; // pks: keyframe number
                }

                for(var i in geometry.materials)
                    geometry.materials[i].morphNormals = true

                if(IMPORT_MORPHNORMALS) {
                
                    if(json.metadata.normals > 0 && json.metadata.morphTargets > 0)
                        geometry.importMorphNormals(json)
                
                } else {

                    geometry.computeVertexNormals()
                    geometry.computeMorphNormals()
                    
                }
                
            }
            
            if(callback)
                callback(geometry)
                
        }

        THREE.JSONLoader.prototype.createModel.call(this, json, Callback, texturePath)
    }
    
    
    THREE.Geometry.prototype.importMorphNormals = function(json) {
    
        var i, il, n, nl, f, fl, x, y, z, vA, vB, vC, cb, ab, vn,
            quads, morphTarget, morphNormals, faceNormals, vertexNormals, tmpVertexNormals
        
        quads = this.faces[0] instanceof THREE.Face4;
    
        for ( i = 0, il = this.morphTargets.length; i < il; i ++ ) {

            jsonNormals = json.morphTargets[ i ].normals;
            
            morphTarget = this.morphTargets[ i ];
        
            faceNormals = [];
            vertexNormals = [];
            morphNormals = this.morphNormals.push( {
            
                faceNormals: faceNormals,
                vertexNormals: vertexNormals
                
            } );


            // these are duplicated by reference in morphNormals[n].vertexNormals

            tmpVertexNormals = [];
            
            for( n = 0, nl = jsonNormals.length; n < nl; n += 3 ) {
                
                x = jsonNormals[ n ];
                y = jsonNormals[ n + 1 ];
                z = jsonNormals[ n + 2 ];
                
                vn = new THREE.Vector3(x, y, z)

                tmpVertexNormals.push(vn);
            }
            
            morphTarget.tmpVertexNormals = tmpVertexNormals
            

            cb = new THREE.Vector3()
            ab = new THREE.Vector3();
    
            for ( f = 0, fl = this.faces.length; f < fl; f ++ ) {
    
                face = this.faces[ f ];
    
                // from Geometry.computeFaceNormals()
                
                vA = morphTarget.vertices[ face.a ];
                vB = morphTarget.vertices[ face.b ];
                vC = morphTarget.vertices[ face.c ];
    
                cb.sub( vC.position, vB.position );
                ab.sub( vA.position, vB.position );
                cb.crossSelf( ab );
    
                if ( !cb.isZero() ) {
    
                    cb.normalize();
    
                }
    
                faceNormals.push( cb.clone() );


                if( quads ) {
                
                    vertexNormals.push( {
                    
                        a: tmpVertexNormals[ face.a ],
                        b: tmpVertexNormals[ face.b ],
                        c: tmpVertexNormals[ face.c ]
                        
                    } )
                
                } else {
                
                    vertexNormals.push( {
                    
                        a: tmpVertexNormals[ face.a ],
                        b: tmpVertexNormals[ face.b ],
                        c: tmpVertexNormals[ face.c ],
                        d: tmpVertexNormals[ face.d ]
                        
                    } )
                
                }

            }

        }
    
    }

    
    Res3D.Loader = Loader;
    
})()

//@ sourceURL=views/Res3D/Loader.js
