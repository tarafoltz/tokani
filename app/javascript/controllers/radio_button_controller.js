import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["fieldset", "typeselected"]

  // This method is very specific to the Edit Appointment page. Like the comment below says,
  // this could be moved to a dedicated controller if we need a more generic radio button controller.
  connect() {
    const selectedFieldSet = this.typeselectedTarget

    this.fieldsetTargets.forEach( fs => {
      if (fs.id == this.typeselectedTarget.value) {
        fs.disabled = false
        fs.querySelectorAll('div.multiselect__container').forEach(so => {so.disabled = false })
        fs.querySelectorAll('input').forEach(so => {so.disabled = false })
        fs.querySelectorAll('.selected-option', 'div.input-group').forEach(so => {so.classList.remove('disabled') })
      } else {
        fs.disabled = true
        fs.querySelectorAll('div.multiselect__container').forEach(so => {so.disabled = true })
        fs.querySelectorAll('input').forEach(so => {so.disabled = true })
        fs.querySelectorAll('input').forEach(so => {so.value = "" })
        fs.querySelectorAll('.selected-option').forEach(so => {so.classList.add('disabled')})
      }
    })
  }

  selectFieldset(event) {
    
    // disable all fieldsets, only enable the current one
    // add to selector classes for 'input like' divs that you want to disable.
    const selectedFieldset = event.params.fieldset
    this.fieldsetTargets.forEach( fs => {
      if (fs.id == selectedFieldset) {
        fs.disabled = false
        fs.querySelectorAll('div.multiselect__container').forEach(so => {so.disabled = false })
        fs.querySelectorAll('input').forEach(so => {so.disabled = false })
        fs.querySelectorAll('.selected-option', 'div.input-group').forEach(so => {so.classList.remove('disabled') })
      } else {
        fs.disabled = true
        fs.querySelectorAll('div.multiselect__container').forEach(so => {so.disabled = true })
        fs.querySelectorAll('input').forEach(so => {so.disabled = true })
        fs.querySelectorAll('input').forEach(so => {so.value = "" })
        fs.querySelectorAll('.selected-option').forEach(so => {so.classList.add('disabled')})
      }
    })
    this.clearFields(event)

  }

  //This is super specific for the default and language selections on pay and bill rates 
  //May need to move to own controller at some point or re-work 
  clearFields(event) {
    const selectedFieldset = event.params.fieldset
    if (selectedFieldset == "default_rate"){
      this.fieldsetTargets.forEach( fs => {
        if (fs.id != selectedFieldset) {
         fs.querySelector('div#languages').setAttribute('data-multiselect-selected-value', "[]")
        
      }
  
    }) 
    }
    
} 

}