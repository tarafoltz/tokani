class CreateAppointmentSpecialties < ActiveRecord::Migration[7.0]
  def change
    create_table :appointment_specialties do |t|
      t.references :appointment, null: false, foreign_key: true
      t.references :specialty, null: false, foreign_key: true

      t.timestamps
    end
  end
end
