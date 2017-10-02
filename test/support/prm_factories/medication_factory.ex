defmodule EHealth.PRMFactories.MedicationFactory do
  @moduledoc false

  alias EHealth.PRM.Medications.INNM.Schema, as: INNM
  alias EHealth.PRM.Medications.INNMDosage.Schema, as: INNMDosage
  alias EHealth.PRM.Medications.INNMDosage.Ingredient, as: INNMDosageIngredient
  alias EHealth.PRM.Medications.Medication.Schema, as: Medication
  alias EHealth.PRM.Medications.Medication.Ingredient, as: MedicationIngredient

  defmacro __using__(_opts) do
    quote do
      alias Ecto.UUID

      def innm_factory do
        %INNM{
          sctid: sequence("1234567"),
          name: "Преднизолон",
          name_original: "Prednisolonum",
          is_active: true,
          updated_by: UUID.generate(),
          inserted_by: UUID.generate(),
        }
      end

      def innm_dosage_factory do
        form = Enum.random(["Pill", "Nebuliser suspension"])

        id = UUID.generate()
        %{id: innm_id} = insert(:prm, :innm)

        %INNMDosage{
          id: id,
          name: sequence("Prednisolonum Forte"),
          type: INNMDosage.type(),
          form: form,
          ingredients: [build(:ingredient_innm_dosage, [innm_child_id: innm_id, parent_id: id])],
          is_active: true,
          updated_by: UUID.generate(),
          inserted_by: UUID.generate(),
        }
      end

      def medication_factory do
        form = Enum.random(["Pill", "Nebuliser suspension"])

        id = UUID.generate()
        %{id: innm_dosage_id} = insert(:prm, :innm_dosage)

        %Medication{
          id: id,
          name: sequence("Prednisolonum Forte"),
          type: Medication.type(),
          form: form,
          ingredients: [build(:ingredient_medication, [medication_child_id: innm_dosage_id, parent_id: id])],
          container: container(form),
          manufacturer: build(:manufacturer),
          package_qty: 10,
          package_min_qty: 30,
          certificate: to_string(3_300_000_000 + :rand.uniform(99_999_999)),
          certificate_expired_at: ~D[2012-04-17],
          is_active: true,
          code_atc: sequence("C08CA0"),
          updated_by: UUID.generate(),
          inserted_by: UUID.generate(),
        }
      end

      def ingredient_factory do
        %{
          id: UUID.generate(),
          is_primary: true,
          dosage: %{
            numerator_unit: "mg",
            numerator_value: 5,
            denumerator_unit: "g",
            denumerator_value: 1
          }
        }
      end

      def ingredient_innm_dosage_factory do
        %INNMDosageIngredient{
          id: UUID.generate(),
          innm_child_id: UUID.generate(),
          parent_id: UUID.generate(),
          is_primary: true,
          dosage: %{
            numerator_unit: "mg",
            numerator_value: 5,
            denumerator_unit: "g",
            denumerator_value: 1
          }
        }
      end

      def ingredient_medication_factory do
        %MedicationIngredient{
          id: UUID.generate(),
          medication_child_id: UUID.generate(),
          parent_id: UUID.generate(),
          is_primary: true,
          dosage: %{
            numerator_unit: "mg",
            numerator_value: 5,
            denumerator_unit: "g",
            denumerator_value: 1
          }
        }
      end

      def manufacturer_factory do
        %{
          name: "ПАТ `Київський вітамінний завод`",
          country: "UA"
        }
      end

      def container("Pill") do
        %{
          numerator_unit: "pill",
          numerator_value: 1,
          denumerator_unit: "pill",
          denumerator_value: 1
        }
      end

      def container("Nebuliser suspension") do
        %{
          numerator_unit: "ml",
          numerator_value: 2,
          denumerator_unit: "container",
          denumerator_value: 1
        }
      end
    end
  end
end