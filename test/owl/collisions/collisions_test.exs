defmodule Owl.CollisionsTest do
  use Owl.DataCase

  import Owl.Factory

  alias Owl.Collisions

  describe "list/0" do
    test "returns all collisions" do
      collision1 = insert(:collision)
      collision2 = insert(:collision)

      assert Enum.sort_by(Collisions.list(), & &1.uuid) ==
               Enum.sort_by([collision1, collision2], & &1.uuid)
    end
  end

  describe "list_uuids_by_collision_id_and_year/2" do
    test "returns map of {collision_id, year} => uuid for matching records" do
      c1 = insert(:collision, collision_id: 1, year: 2020)
      c2 = insert(:collision, collision_id: 1, year: 2021)
      # irrelevant
      insert(:collision, collision_id: 2, year: 2020)

      result =
        [1]
        |> Collisions.list_uuids_by_collision_id_and_year([2020, 2021])
        |> Map.new(fn {{col_id, yr}, uuid} -> {{col_id, yr}, uuid} end)

      assert result == %{
               {1, 2020} => c1.uuid,
               {1, 2021} => c2.uuid
             }
    end
  end

  describe "calculate_total_collisions/1 and count_collisions/1" do
    test "counts collisions correctly with severity filters" do
      insert_pair(:collision, severity: :fatal, year: 2021)
      insert_pair(:collision, severity: :serious, year: 2021)
      insert_pair(:collision, severity: :slight, year: 2021)
      insert(:collision, severity: :slight, year: 2022)

      params = %{
        fatal: true,
        serious: false,
        slight: true,
        start_year: 2021,
        end_year: 2021
      }

      assert Collisions.calculate_total_collisions(params) == 4
      assert Collisions.count_collisions(params) == 4
    end

    # TODO should be changed to return 0, should be enough to handle validation in LiveView
    test "returns 5 when no severities selected" do
      insert_list(5, :collision, year: 2021)

      params = %{
        fatal: false,
        serious: false,
        slight: false,
        start_year: 2021,
        end_year: 2021
      }

      assert Collisions.calculate_total_collisions(params) == 5
    end
  end

  describe "calculate_total_casualties/1" do
    test "sums total_casualties with filters" do
      insert(:collision, total_casualties: 3, severity: :fatal, year: 2020)
      insert(:collision, total_casualties: 5, severity: :serious, year: 2020)
      insert(:collision, total_casualties: 2, severity: :slight, year: 2021)

      params = %{
        fatal: true,
        serious: true,
        slight: false,
        start_year: 2020,
        end_year: 2020
      }

      assert Collisions.calculate_total_casualties(params) == 8
    end
  end

  describe "calculate_fatal_casualties/1" do
    test "counts only fatal collisions in year range" do
      insert_list(3, :collision, severity: :fatal, year: 2019)
      insert_list(2, :collision, severity: :fatal, year: 2020)
      insert(:collision, severity: :serious, year: 2020)

      assert Collisions.calculate_fatal_casualties(%{start_year: 2020, end_year: 2020}) == 2
    end
  end

  describe "list_collisions_count_per_month/1" do
    test "groups and counts by month-year" do
      insert(:collision, year: 2022, month: 1)
      insert_pair(:collision, year: 2022, month: 1)
      insert(:collision, year: 2022, month: 3)
      # outside range
      insert(:collision, year: 2021, month: 12)

      result =
        Collisions.list_collisions_count_per_month(%{
          fatal: true,
          serious: true,
          slight: true,
          start_year: 2022,
          end_year: 2022
        })

      assert Enum.sort_by(result, & &1.month) == [
               %{month: "1-2022", count: 3},
               %{month: "3-2022", count: 1}
             ]
    end
  end

  describe "list_collision_details/1" do
    test "returns selected fields with filters" do
      serious_collision = insert(:collision, year: 2021, severity: :serious, district: "Central")
      _slight_collision = insert(:collision, year: 2021, severity: :slight, district: "Central")

      result =
        Collisions.list_collision_details(%{
          fatal: false,
          serious: true,
          slight: false,
          start_year: 2021,
          end_year: 2021
        })

      assert length(result) == 1
      record = List.first(result)
      assert record.uuid == serious_collision.uuid
      assert record.date == serious_collision.day
      assert record.district == "Central"
      assert record.severity == :serious
    end
  end

  describe "list_collision_details_paginated/3" do
    setup do
      collisions =
        insert_list(15, :collision,
          year: 2022,
          severity: :slight
        )

      {:ok, collisions: collisions}
    end

    test "paginates and returns total count" do
      params = %{
        fatal: true,
        serious: true,
        slight: true,
        start_year: 2022,
        end_year: 2022
      }

      result = Collisions.list_collision_details_paginated(params, 5, 10, nil)

      assert result.row_count == 15
      assert length(result.row_data) == 5
    end

    test "sorts by date when sort_model is {:date, :desc}" do
      # Ensure varied dates
      insert(:collision, year: 2022, month: 1, day: 1, hour: 12)
      insert(:collision, year: 2022, month: 6, day: 15, hour: 8)
      insert(:collision, year: 2022, month: 12, day: 30, hour: 23)

      result =
        Collisions.list_collision_details_paginated(
          %{fatal: true, serious: true, slight: true, start_year: 2022, end_year: 2022},
          0,
          3,
          {:date, :desc}
        )

      dates = Enum.map(result.row_data, & &1.date)
      assert DateTime.compare(Enum.at(dates, 0), Enum.at(dates, 1)) in [:gt, :eq]
    end

    test "sorts by other fields" do
      insert(:collision, district: "Zeta", year: 2022)
      insert(:collision, district: "Alpha", year: 2022)

      result =
        Collisions.list_collision_details_paginated(
          %{fatal: true, serious: true, slight: true, start_year: 2022, end_year: 2022},
          0,
          10,
          {:district, :asc}
        )

      districts = Enum.map(result.row_data, & &1.district)
      assert districts == Enum.sort(districts)
    end
  end
end
