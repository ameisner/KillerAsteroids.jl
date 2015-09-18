
function compute_log_prior(ast::AsteroidParams, prior::Prior)
    logpdf(prior.r, ast.r) + logpdf(prior.v, ast.v)
end

"""
Returns the position of the asteroid at time t.
Note: Can make this a nonlinear function here in the future, once the time
of integration is months or years rather than hours.
args
  - u0: position of the asteroid at time 0.
  - v: velocity of the asteroid
  - t: time
"""
function extrapolate_position(u0::Vector{Float64}, v::Vector{Float64}, t::Float64)
    u0 + v * t 
end

function compute_log_likelihood(ast::AsteroidParams, img::Image)
    ll = 0.
    psf_dims = size(img.psf)
    psf_center = [round(Int, (dim + 1) / 2) for dim in size(img.psf)]
    u_t = extrapolate_position(ast.u, ast.v, img.t)
    u_t_px = round(Int, u_t)
    for w2 in 1:psf_dims[2], h2 in 1:psf_dims[1]
        h = u_t_px[1] + h2 - psf_center[1]
        w = u_t_px[2] + w2 - psf_center[2]
        expected_ast_dn = (ast.r * img.psf[h2, w2]) / img.nmgy_per_dn
        expected_pixel_dn = img.sky_noise_mean + expected_ast_dn
        pixel_dn_var = expected_pixel_dn + img.read_noise_var
        pixel_dist = Normal(expected_pixel_dn, sqrt(pixel_dn_var))
        ll += logpdf(pixel_dist, img.pixels[h, w])
    end
    ll
end


function compute_log_likelihood(ast::AsteroidParams, img_stack::Vector{Image})
    sum([compute_log_likelihood(ast, img) for img in img_stack])
end


"""
Computes the unnormalized log probability for a particular
candidate asteroid (higher is better)

arguments:
  ast: parameters for a candidate asteroid
  img: an astronomical image
"""
function compute_log_probability(ast::AsteroidParams, 
        img_data::Union(Image, Vector{Image}), prior::Prior)
    compute_log_prior(ast, prior) + compute_log_likelihood(ast, img_data)
end

