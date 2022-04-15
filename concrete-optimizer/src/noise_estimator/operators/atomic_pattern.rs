use crate::parameters::{
    AtomicPatternParameters, BrDecompositionParameters, GlweParameters, KeyswitchParameters,
    PbsParameters,
};
use crate::security;
use concrete_commons::dispersion::{DispersionParameter, Variance};
use concrete_commons::key_kinds::BinaryKeyKind;
use concrete_commons::numeric::UnsignedInteger;
use concrete_commons::parameters::{
    DecompositionBaseLog, DecompositionLevelCount, GlweDimension, LweDimension, PolynomialSize,
};

/// Additional noise generated by the keyswitch step.
pub fn variance_keyswitch<W: UnsignedInteger>(
    param: KeyswitchParameters,
    ciphertext_modulus_log: u64,
    variance_ksk: Variance,
) -> Variance {
    assert_eq!(ciphertext_modulus_log, W::BITS as u64);
    concrete_npe::estimate_keyswitch_noise_lwe_to_glwe_with_constant_terms::<
        W,
        Variance,
        Variance,
        BinaryKeyKind,
    >(
        LweDimension(param.input_lwe_dimension.0 as usize),
        Variance(0.0),
        variance_ksk,
        DecompositionBaseLog(param.ks_decomposition_parameter.log2_base as usize),
        DecompositionLevelCount(param.ks_decomposition_parameter.level as usize),
    )
}

/// Compute the variance parameter of the keyswitch key.
pub fn variance_ksk(
    internal_ks_output_lwe_dimension: u64,
    ciphertext_modulus_log: u64,
    security_level: u64,
) -> Variance {
    let glwe_params = GlweParameters {
        log2_polynomial_size: 0,
        glwe_dimension: internal_ks_output_lwe_dimension,
    };
    // https://github.com/zama-ai/concrete-optimizer/blob/prototype/python/optimizer/noise_formulas/keyswitch.py#L13
    security::glwe::minimal_variance(glwe_params, ciphertext_modulus_log, security_level)
}

/// Additional noise generated by fft computation
pub fn fft_noise<W: UnsignedInteger>(
    internal_ks_output_lwe_dimension: u64, //n_small
    glwe_params: GlweParameters,
    br_decomposition_parameter: BrDecompositionParameters,
) -> Variance {
    // https://github.com/zama-ai/concrete-optimizer/blob/prototype/python/optimizer/noise_formulas/bootstrap.py#L25
    let n = internal_ks_output_lwe_dimension as f64;
    let b = 2_f64.powi(br_decomposition_parameter.log2_base as i32);
    let l = br_decomposition_parameter.level as f64;
    let big_n = glwe_params.polynomial_size() as f64;
    // 22 = 2 x 11, 11 = 64 -53
    let scale_margin = (1_u64 << 22) as f64;
    let res = n * 0.1 * scale_margin * l * b * b * big_n.powf(2.0);
    Variance::from_modular_variance::<W>(res)
}

/// Final reduced noise generated by the final bootstrap step.
/// Note that it does not depends from input noise, assuming the bootstrap is successful
pub fn variance_bootstrap<W: UnsignedInteger>(
    param: PbsParameters,
    ciphertext_modulus_log: u64,
    variance_bsk: Variance,
) -> Variance {
    assert_eq!(ciphertext_modulus_log, W::BITS as u64);
    let out_variance_pbs = concrete_npe::estimate_pbs_noise::<W, Variance, BinaryKeyKind>(
        LweDimension(param.internal_lwe_dimension.0 as usize),
        PolynomialSize(param.output_glwe_params.polynomial_size() as usize),
        GlweDimension(param.output_glwe_params.glwe_dimension as usize),
        DecompositionBaseLog(param.br_decomposition_parameter.log2_base as usize),
        DecompositionLevelCount(param.br_decomposition_parameter.level as usize),
        variance_bsk,
    );

    let additional_fft_noise = fft_noise::<W>(
        param.internal_lwe_dimension.0,
        param.output_glwe_params,
        param.br_decomposition_parameter,
    );
    Variance(out_variance_pbs.get_variance() + additional_fft_noise.get_variance())
}

pub fn estimate_modulus_switching_noise_with_binary_key<W>(
    internal_ks_output_lwe_dimension: u64,
    glwe_polynomial_size: u64,
) -> Variance
where
    W: UnsignedInteger,
{
    #[allow(clippy::cast_sign_loss)]
    let nb_msb = (f64::log2(glwe_polynomial_size as f64) as usize) + 1;
    concrete_npe::estimate_modulus_switching_noise_with_binary_key::<W, Variance>(
        LweDimension(internal_ks_output_lwe_dimension as usize),
        nb_msb,
        Variance(0.0),
    )
}

pub fn maximal_noise<D, W>(
    input_variance: Variance,

    param: AtomicPatternParameters,
    ciphertext_modulus_log: u64, //log(q)

    security_level: u64,
) -> Variance
where
    D: DispersionParameter,
    W: UnsignedInteger,
{
    assert_eq!(ciphertext_modulus_log, W::BITS as u64);
    let v_keyswitch = variance_keyswitch::<W>(
        param.ks_parameters(),
        ciphertext_modulus_log,
        variance_ksk(
            param.internal_lwe_dimension.0,
            ciphertext_modulus_log,
            security_level,
        ),
    );
    let v_modulus_switch = estimate_modulus_switching_noise_with_binary_key::<W>(
        param.internal_lwe_dimension.0,
        param.output_glwe_params.polynomial_size(),
    );
    Variance(
        input_variance.get_variance()
            + v_keyswitch.get_variance()
            + v_modulus_switch.get_variance(),
    )
}

/// The maximal noise is attained at the end of the modulus switch.
pub fn maximal_noise_multi_sum<D, W, Ignored>(
    dispersions: &[D],
    weights_tuples: &[(W, Ignored)],
    param: AtomicPatternParameters,
    ciphertext_modulus_log: u64,

    security_level: u64,
) -> Variance
where
    D: DispersionParameter,
    W: UnsignedInteger,
{
    assert_eq!(ciphertext_modulus_log, W::BITS as u64);
    let v_out_multi_sum = if dispersions.is_empty() {
        let mut weights = vec![];
        for (weight, _) in weights_tuples.iter() {
            weights.push(*weight);
        }
        concrete_npe::estimate_weighted_sum_noise(dispersions, weights.as_slice())
    } else {
        Variance(0.0)
    };
    maximal_noise::<D, W>(
        v_out_multi_sum,
        param,
        ciphertext_modulus_log,
        security_level,
    )
}

/// The output noise is the variance boostrap.
pub fn output_noise<D, W>(
    param: AtomicPatternParameters,
    ciphertext_modulus_log: u64,
    security_level: u64,
) -> Variance
where
    D: DispersionParameter,
    W: UnsignedInteger,
{
    // https://github.com/zama-ai/concrete-optimizer/blob/prototype/python/optimizer/noise_formulas/bootstrap.py#L66
    let variance_bsk = security::glwe::minimal_variance(
        param.output_glwe_params,
        ciphertext_modulus_log,
        security_level,
    );
    variance_bootstrap::<W>(param.pbs_parameters(), ciphertext_modulus_log, variance_bsk)
}

#[cfg(test)]
mod tests {
    use crate::parameters::{
        BrDecompositionParameters, GlweParameters, KsDecompositionParameters, LweDimension,
    };

    use super::*;

    #[test]
    fn golden_python_prototype_security_variance_keyswitch_1() {
        let golden_modular_variance = 3.260_702_274_017_557e68;
        let internal_ks_output_lwe_dimension = 1024;
        let ciphertext_modulus_log = 128;
        let security = 128;

        let param = KeyswitchParameters {
            input_lwe_dimension: LweDimension(4096),
            output_lwe_dimension: LweDimension(internal_ks_output_lwe_dimension),
            ks_decomposition_parameter: KsDecompositionParameters {
                level: 9,
                log2_base: 5,
            },
        };

        let actual = variance_keyswitch::<u128>(
            param,
            ciphertext_modulus_log,
            variance_ksk(
                internal_ks_output_lwe_dimension,
                ciphertext_modulus_log,
                security,
            ),
        )
        .get_modular_variance::<u128>();
        approx::assert_relative_eq!(actual, golden_modular_variance, max_relative = 1e-8);
    }

    #[test]
    fn golden_python_prototype_security_variance_keyswitch_2() {
        // let golden_modular_variance = 8.580795457940938e+66;
        // the full npe implements a part of the full estimation
        let golden_modular_variance = 3.941_898_681_369_209e48; // full estimation
        let internal_ks_output_lwe_dimension = 512;
        let ciphertext_modulus_log = 64;
        let security = 128;

        let param = KeyswitchParameters {
            input_lwe_dimension: LweDimension(2048),
            output_lwe_dimension: LweDimension(internal_ks_output_lwe_dimension),
            ks_decomposition_parameter: KsDecompositionParameters {
                level: 2,
                log2_base: 24,
            },
        };

        let actual = variance_keyswitch::<u64>(
            param,
            ciphertext_modulus_log,
            variance_ksk(
                internal_ks_output_lwe_dimension,
                ciphertext_modulus_log,
                security,
            ),
        )
        .get_modular_variance::<u64>();
        approx::assert_relative_eq!(actual, golden_modular_variance, max_relative = 1e-8);
    }

    #[test]
    fn security_variance_bootstrap_1() {
        let ref_modular_variance = 8.112_963_910_722_068e30;
        let glwe_params = GlweParameters {
            log2_polynomial_size: 12,
            glwe_dimension: 10,
        };
        let ciphertext_modulus_log = 64;
        let security = 128;
        let variance_bsk =
            security::glwe::minimal_variance(glwe_params, ciphertext_modulus_log, security);

        let param = PbsParameters {
            internal_lwe_dimension: LweDimension(2048),
            br_decomposition_parameter: BrDecompositionParameters {
                level: 2,
                log2_base: 24,
            },
            output_glwe_params: glwe_params,
        };

        let actual = variance_bootstrap::<u64>(param, ciphertext_modulus_log, variance_bsk)
            .get_modular_variance::<u64>();
        approx::assert_relative_eq!(actual, ref_modular_variance, max_relative = 1e-8);
    }

    #[test]
    fn golden_python_prototype_security_variance_bootstrap_2() {
        // golden value include fft correction
        let golden_modular_variance = 1.307_769_436_943_601_9e56;
        let glwe_params = GlweParameters {
            log2_polynomial_size: 12,
            glwe_dimension: 16,
        };
        let ciphertext_modulus_log = 128;
        let security = 128;
        let variance_bsk =
            security::glwe::minimal_variance(glwe_params, ciphertext_modulus_log, security);

        let param = PbsParameters {
            internal_lwe_dimension: LweDimension(1024),
            br_decomposition_parameter: BrDecompositionParameters {
                level: 9,
                log2_base: 5,
            },
            output_glwe_params: glwe_params,
        };

        let actual = variance_bootstrap::<u128>(param, ciphertext_modulus_log, variance_bsk)
            .get_modular_variance::<u128>();
        approx::assert_relative_eq!(actual, golden_modular_variance, max_relative = 1e-8);
    }
}
